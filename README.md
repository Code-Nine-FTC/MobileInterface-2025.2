# MobileInterface

Este projeto segue uma arquitetura em camadas para garantir organização, escalabilidade e facilidade de manutenção. As principais camadas são: **Presentation (UI)**, **Domain (regras de negócio)**, **Data (dados externos)** e **Core (utilitários compartilhados)**.

---

## Estrutura de Pastas

### main.dart
- **Função:** Ponto de entrada da aplicação Flutter. Inicializa o app, configura temas, rotas e dependências.

### core/
- **Função:** Utilitários e configurações compartilhadas.
- **theme/**: Define estilos visuais (cores, textos, temas) para consistência na UI.
- **utils/**: Ferramentas auxiliares e serviços como armazenamento seguro.

### data/
- **Função:** Camada de dados – lida com fontes externas (APIs, bancos locais).
- **api/**: Fontes de dados remotas.
- **models/**: Modelos de dados para mapear respostas de APIs.
- **repositories/**: Implementações concretas dos repositórios definidos no domínio.

### domain/
- **Função:** Camada de domínio – contém regras de negócio e contratos (interfaces).
- **auth/**: Lógica de autenticação.
- **entities/**: Entidades de negócio puras, sem dependências externas.

### presentation/
- **Função:** Camada de apresentação – UI e interação do usuário.
- **components/**: Componentes reutilizáveis de UI.
- **controllers/**: Gerenciamento de estado e lógica de UI.
- **pages/**: Telas organizadas por domínio (login, menu, pedidos, estoque, fornecedores, usuários).

### routes/
- **Função:** Configuração de navegação entre telas.
- **home-router.dart**: Define rotas nomeadas (ex: `/login`, `/menu`).

---

## Benefícios da Arquitetura

- **Organização:** Separação clara de responsabilidades.
- **Escalabilidade:** Facilita adição de novas funcionalidades.
- **Testabilidade:** Camadas desacopladas facilitam testes unitários e de integração.
- **Manutenção:** Mudanças em uma camada têm impacto mínimo nas demais.

---

## Observações

- Utilize os arquivos de tema para manter a consistência visual.
- Siga os contratos definidos na camada de domínio ao implementar repositórios e serviços.
- Prefira componentes reutilizáveis para evitar duplicação de código.

---

> Para mais detalhes sobre cada camada ou componente, consulte os arquivos correspondentes no repositório.