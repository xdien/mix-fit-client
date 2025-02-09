# Mit-Fix Project

Mit-Fix is a personal Flutter project that implements clean architecture principles and industry best practices in mobile development. Built upon established architectural patterns, this project showcases how to structure a real-world application that is scalable, maintainable, and testable.

## 🎯 Project Overview

This project adheres to Clean Architecture principles, separating the codebase into distinct layers with clear responsibilities:

* **Domain Layer**: Business logic and entities
* **Data Layer**: Data sources, repositories, and models
* **Presentation Layer**: UI components and state management
* **Core Layer**: Common utilities and configurations

## 🏛 Architecture Principles

* **Separation of Concerns**: Each layer has its specific responsibility
* **Dependency Rule**: Dependencies point inward, with the domain layer at the center
* **SOLID Principles**: Following all SOLID principles for better maintainability
* **Testability**: Architecture designed for easy unit testing and integration testing

## 🚀 Features

* Clean Architecture implementation
* Dependency Injection
* State Management with MobX
* Repository Pattern
* Unit Testing Setup
* Error Handling
* API Integration
* Local Storage
* Logging System
* Authentication Flow

## 🛠 Technical Stack

* **Framework**: Flutter
* **State Management**: MobX
* **Dependency Injection**: GetIt
* **Local Database**: Drift
* **Network**: Dio
* **Code Generation**: build_runner
* **Testing**: flutter_test
* **API Documentation**: OpenAPI Generator

## 📁 Project Structure

```
lib/
├── core/                 # Core functionality, utilities, and constants
│   ├── config/          # App configuration
│   ├── error/           # Error handling
│   ├── network/         # Network utilities
│   └── utils/           # Common utilities
│
├── data/                # Data layer
│   ├── datasources/     # Remote and local data sources
│   ├── models/          # Data models
│   └── repositories/    # Repository implementations
│
├── domain/              # Domain layer
│   ├── entities/        # Business objects
│   ├── repositories/    # Repository interfaces
│   └── usecases/       # Business logic
│
├── presentation/        # Presentation layer
│   ├── pages/          # Screen implementations
│   ├── stores/         # MobX stores
│   └── widgets/        # Reusable widgets
│
└── main.dart           # Application entry point
```

## 🏁 Getting Started

1. Clone the repository:

```bash
git clone https://github.com/xdien/mit-fix.git
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run code generation:

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

4. Run the app:

```bash
flutter run
```

## 🧪 Testing

Run tests using:

```bash
flutter test
```

The project includes:

* Unit Tests
* Widget Tests
* Integration Tests

## 📚 Best Practices

* **Dependency Injection**: Using GetIt for service location
* **Repository Pattern**: Abstracting data sources
* **Error Handling**: Centralized error handling system
* **Logging**: Structured logging system
* **Code Style**: Following Flutter's style guide
* **Documentation**: Comprehensive code documentation

## 🤝 Contributing

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎯 Why Clean Architecture?

Clean Architecture provides several benefits:

* **Independence of Framework**: The business logic doesn't depend on Flutter or any external framework
* **Testability**: Easy to test due to separation of concerns
* **Independence of UI**: The UI can change without affecting business logic
* **Independence of Database**: Your choice of database can be changed without affecting the business logic
* **Independence of External Agency**: Business rules don't know anything about the outside world

## 🔍 Documentation

For detailed documentation about the architecture and implementation details, check the `/docs` folder in the repository.
