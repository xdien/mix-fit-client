# Mix-Fit Project

Mix-Fit is a personal Flutter project that implements clean architecture principles and industry best practices in mobile development. Built upon established architectural patterns, this project showcases how to structure a real-world application that is scalable, maintainable, and testable. [Test commit]

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

2. Setup development configuration:

```bash
cd frontend
./scripts/setup_dev_config.sh
```

3. Install dependencies:

```bash
flutter pub get
```

4. Run code generation:

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

5. Start backend services (in another terminal):

```bash
cd ../backend
./start-ankhanh.sh
yarn start:dev
```

6. Run the app:

```bash
flutter run -d linux
```

## 🔧 Development Configuration

The application uses environment-specific configuration files located in `config/environments/`:

- `development.yaml.example` - Template for development environment
- `development.yaml` - Your local development configuration (gitignored)
- `staging.yaml` - Staging environment configuration (gitignored)
- `production.yaml` - Production environment configuration (gitignored)

### Initial Setup

### WebSocket Configuration

For local development with WebSocket support:

1. **Ensure backend is running** on `localhost:3000`
2. **Verify WebSocket configuration** in `config/environments/development.yaml`:
   ```yaml
   network:
     api_base_url: http://localhost:3000/api
     websocket_url: ws://localhost:3000
   ```

3. **Test WebSocket connection**:
   ```bash
   # From backend directory
   node test-ankhanh-websocket.js
   ```

For more details, see [Environment Configuration Guide](config/environments/README.md).

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
