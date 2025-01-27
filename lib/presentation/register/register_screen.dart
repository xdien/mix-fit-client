// register_screen.dart
import 'dart:io';

import 'package:another_flushbar/flushbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';

import '../../di/service_locator.dart';
import 'store/register_store.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final RegisterStore _store = getIt<RegisterStore>();
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng ký'),
      ),
      body: Observer(
        builder: (_) => Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar picker
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _store.avatar != null
                        ? FileImage(_store.avatar!)
                        : null,
                    child: _store.avatar == null
                        ? Icon(Icons.camera_alt, size: 30)
                        : null,
                  ),
                ),
                SizedBox(height: 20),

                // Username field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Tên đăng nhập',
                    prefixIcon: Icon(Icons.person),
                  ),
                  onChanged: _store.setUsername,
                  validator: (value) =>
                      value?.isEmpty == true ? 'Vui lòng nhập tên đăng nhập' : null,
                ),
                SizedBox(height: 16),

                // Email field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: _store.setEmail,
                  validator: (value) =>
                      value?.isEmpty == true ? 'Vui lòng nhập email' : null,
                ),
                SizedBox(height: 16),

                // Password field
                Observer(
                  builder: (_) => TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _store.passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: _store.togglePasswordVisibility,
                      ),
                    ),
                    obscureText: !_store.passwordVisible,
                    onChanged: _store.setPassword,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Vui lòng nhập mật khẩu' : null,
                  ),
                ),
                SizedBox(height: 16),

                // Full name field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  onChanged: _store.setFullName,
                  validator: (value) =>
                      value?.isEmpty == true ? 'Vui lòng nhập họ và tên' : null,
                ),
                SizedBox(height: 16),

                // Phone field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: _store.setPhone,
                  validator: (value) =>
                      value?.isEmpty == true ? 'Vui lòng nhập số điện thoại' : null,
                ),
                SizedBox(height: 24),

                // Register button
                Observer(
                  builder: (_) => ElevatedButton(
                    onPressed: _store.isLoading || !_store.canRegister
                        ? null
                        : _handleRegister,
                    child: _store.isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Đăng ký'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _store.setAvatar(File(pickedFile.path));
    }
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() == true) {
      final success = await _store.register();
      if (success) {
        FlushbarHelper.createSuccess(
          message: 'Đăng ký thành công!',
        ).show(context);
        Navigator.of(context).pop();
      } else {
        FlushbarHelper.createError(
          message: _store.errorStore.errorMessage,
        ).show(context);
      }
    }
  }
}