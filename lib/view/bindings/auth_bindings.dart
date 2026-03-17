import 'package:get/get.dart';


import '../../controller/auth/login_controller.dart';
import '../../services/auth/auth_service.dart';

class AuthBindings implements Bindings {
  @override
  void dependencies() {
    // Initialize services
    Get.lazyPut(() => AuthService(), fenix: true);

    // Initialize controllers
    Get.lazyPut(() => LoginController(), fenix: true);
  }
}