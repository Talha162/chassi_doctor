'use strict';

const admin = require('firebase-admin');
const { onRequest } = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
const { defineSecret } = require('firebase-functions/params');
const { createClient } = require('@supabase/supabase-js');

admin.initializeApp();

const supabaseUrlSecret = defineSecret('SUPABASE_URL');
const supabaseServiceRoleKeySecret = defineSecret('SUPABASE_SERVICE_ROLE_KEY');
const webhookSecret = defineSecret('SUPABASE_WEBHOOK_SECRET');

function createSupabaseAdminClient() {
  return createClient(
    supabaseUrlSecret.value(),
    supabaseServiceRoleKeySecret.value(),
    {
      auth: { persistSession: false, autoRefreshToken: false },
    }
  );
}

async function markEventStatus(supabase, eventId, patch) {
  const update = { ...patch };
  if (patch.status === 'processed') {
    update.processed_at = new Date().toISOString();
    update.error_message = null;
  }

  const { error } = await supabase
    .from('notification_events')
    .update(update)
    .eq('id', eventId);

  if (error) {
    logger.error('Failed to update notification event status', { eventId, error });
  }
}

async function fetchRecipients(supabase, eventId) {
  const { data, error } = await supabase.rpc('get_notification_event_recipients', {
    p_event_id: eventId,
  });

  if (error) {
    throw error;
  }

  return data || [];
}

function dedupeRecipients(rows) {
  const byUser = new Map();

  for (const row of rows) {
    const existing = byUser.get(row.user_id);
    if (existing) {
      existing.tokens.push(row.token);
      continue;
    }

    byUser.set(row.user_id, {
      userId: row.user_id,
      title: row.title,
      body: row.body,
      payload: row.payload || {},
      tokens: [row.token],
    });
  }

  return [...byUser.values()];
}

async function createInAppNotifications(supabase, eventId, recipients) {
  if (!recipients.length) return;

  const rows = recipients.map((recipient) => ({
    user_id: recipient.userId,
    notification_event_id: eventId,
    title: recipient.title,
    body: recipient.body,
    data: recipient.payload,
  }));

  const { error } = await supabase.from('user_notifications').insert(rows);
  if (error) {
    throw error;
  }
}

async function deleteInvalidTokens(supabase, tokens) {
  if (!tokens.length) return;

  const { error } = await supabase.from('device_tokens').delete().in('token', tokens);
  if (error) {
    logger.error('Failed to delete invalid device tokens', { error, tokens });
  }
}

exports.handleLearningNotificationEvent = onRequest(
  {
    region: 'us-central1',
    maxInstances: 10,
    invoker: 'public',
    cpu: 1,
    secrets: [
      supabaseUrlSecret,
      supabaseServiceRoleKeySecret,
      webhookSecret,
    ],
  },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const expectedSecret = webhookSecret.value();
    const incomingSecret =
      req.get('x-webhook-secret') || req.get('X-Webhook-Secret');

    if (incomingSecret !== expectedSecret) {
      logger.warn('Rejected webhook with invalid secret');
      res.status(401).json({ ok: false, error: 'invalid_secret' });
      return;
    }

    const eventId = req.body && req.body.record && req.body.record.id;
    if (!eventId) {
      res.status(400).json({ ok: false, error: 'missing_event_id' });
      return;
    }

    const supabase = createSupabaseAdminClient();

    try {
      const recipientRows = await fetchRecipients(supabase, eventId);
      const recipients = dedupeRecipients(recipientRows);

      if (!recipients.length) {
        await markEventStatus(supabase, eventId, {
          status: 'processed',
          error_message: null,
        });
        res.status(200).json({ ok: true, eventId, recipients: 0, sent: 0 });
        return;
      }

      await createInAppNotifications(supabase, eventId, recipients);

      const invalidTokens = [];
      let sentCount = 0;

      for (const recipient of recipients) {
        const message = {
          notification: {
            title: recipient.title,
            body: recipient.body,
          },
          data: Object.fromEntries(
            Object.entries(recipient.payload || {}).map(([key, value]) => [
              key,
              value == null ? '' : String(value),
            ])
          ),
          tokens: [...new Set(recipient.tokens)].filter(Boolean),
        };

        if (!message.tokens.length) {
          continue;
        }

        const response = await admin.messaging().sendEachForMulticast(message);
        sentCount += response.successCount;

        response.responses.forEach((result, index) => {
          if (!result.success) {
            const code = result.error && result.error.code;
            if (
              code === 'messaging/invalid-registration-token' ||
              code === 'messaging/registration-token-not-registered'
            ) {
              invalidTokens.push(message.tokens[index]);
            }
            logger.error('FCM send failure', {
              eventId,
              userId: recipient.userId,
              token: message.tokens[index],
              code,
              message: result.error && result.error.message,
            });
          }
        });
      }

      await deleteInvalidTokens(supabase, invalidTokens);

      await markEventStatus(supabase, eventId, {
        status: 'processed',
        error_message: null,
      });

      res.status(200).json({
        ok: true,
        eventId,
        recipients: recipients.length,
        sent: sentCount,
        invalidTokensRemoved: invalidTokens.length,
      });
    } catch (error) {
      logger.error('Failed to process notification event', { eventId, error });
      await markEventStatus(supabase, eventId, {
        status: 'failed',
        error_message: error.message || String(error),
      });
      res.status(500).json({
        ok: false,
        eventId,
        error: error.message || String(error),
      });
    }
  }
);
