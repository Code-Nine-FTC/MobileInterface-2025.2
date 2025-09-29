# MobileInterface-2025.2 – Manual de Instalação

## Visão Geral

**MobileInterface-2025.2** é um aplicativo Flutter multiplataforma (Dart) com componentes nativos (C++, CMake, Swift, C, HTML). Ele suporta Android, iOS, Windows, Linux e web. O projeto utiliza uma arquitetura modular para facilitar a manutenção e a escalabilidade.

---

## 1. Pré-requisitos

- **Flutter SDK**: [Instale o Flutter](https://docs.flutter.dev/get-started/install) (versão compatível com o projeto)
- **Dart SDK**: Incluído no Flutter
- **CMake**: Para builds desktop (Linux/Windows)
- **IDE**: VS Code, Android Studio ou IntelliJ (recomenda-se o plugin Flutter)
- **Ferramentas de build Android/iOS** (caso vá rodar em dispositivos móveis)

---

## 2. Clonando o Repositório

```bash
git clone https://github.com/Code-Nine-FTC/MobileInterface-2025.2.git
cd MobileInterface-2025.2
```

---

## 3. Estrutura do Projeto

- `main.dart` — Ponto de entrada da aplicação Flutter
- `core/` — Utilitários compartilhados, temas e armazenamento seguro
- `data/` — Camada de acesso a dados (APIs, models, repositórios)
- `domain/` — Contratos de regra de negócio e entidades
- `presentation/` — Componentes de UI, controllers e páginas
- `routes/` — Definições de navegação
- `linux/`, `windows/`, `macos/` — Código nativo e build específico de plataforma
- `web/` — Arquivos de suporte para web

*Consulte o README para mais detalhes das pastas.*

---

## 4. Instalando Dependências

```bash
flutter pub get
```

---

## 5. Executando a Aplicação

### Android / iOS

- Conecte um dispositivo ou inicie um emulador.
- Execute:
  ```bash
  flutter run
  ```

### Web

```bash
flutter run -d chrome
```

### Windows

- Certifique-se de que o CMake e o Visual Studio estejam instalados.
- Execute:
  ```bash
  flutter run -d windows
  ```

### Linux

- Instale GTK 3, CMake e build-essentials.
- Execute:
  ```bash
  flutter run -d linux
  ```

---

## 6. Gerando Build de Produção

Consulte a [documentação do Flutter](https://docs.flutter.dev/deployment) para builds de produção em cada plataforma.

---

## 7. Notas por Plataforma

- **Linux/Windows**: Os arquivos `CMakeLists.txt` em `linux/` e `windows/` trazem as configurações de build. Builds nativos dependem do CMake e de dependências do sistema (ex: GTK para Linux).
- **Web**: Pode ser necessário configurar plugins adicionais para web.

---

## 8. Dicas Adicionais

- Use os arquivos de tema em `core/theme/` para garantir UI consistente.
- Siga os contratos de `domain/` para implementar repositórios e serviços.
- Prefira componentes reutilizáveis em `presentation/components/` para evitar duplicidade de código.

---

## 9. Solução de Problemas

- Se encontrar dependências faltando, sempre rode `flutter pub get`.
- Para builds nativos, garanta que os SDKs e toolchains estejam instalados na sua plataforma.
- Para mais detalhes, veja o README do projeto e o guia de troubleshooting do Flutter.

---
