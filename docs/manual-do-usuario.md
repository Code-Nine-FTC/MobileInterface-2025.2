# MobileInterface-2025.2 – Manual do Usuário

## Visão Geral

MobileInterface-2025.2 é um app Flutter modular para gestão de produtos e perfis de usuário, com arquitetura escalável e por camadas. A interface oferece navegação intuitiva para ações principais, cadastro de produtos, gestão de estoque e controle de perfil do usuário.

---

## 1. Funcionalidades Principais

- **Gestão de Produtos**: Cadastro e gerenciamento de produtos, incluindo estoque, fornecedores e tipos de item.
- **Gestão de Perfil**: Visualização e atualização de dados do perfil, troca de senha e logout.
- **Navegação**: Menus adaptados ao perfil do usuário (ex: ADMIN), com atalhos para ações principais.
- **Autenticação**: Login/logout seguro, armazenamento de token e gerenciamento da sessão.

---

## 2. Navegação

- O menu principal se adapta ao perfil do usuário (ex: ADMIN).
- Use a barra de navegação inferior ou os cartões do menu para acessar:
  - Cadastro de Produto (`/register_product`)
  - Lista de Estoque (`/home` ou `/estoque`)
  - Perfil & Configurações (`/profile`, `/settings`)
  - Ações administrativas via `/adiminMenu`

---

## 3. Fluxos de Uso Comuns

### 3.1. Login e Autenticação

- Ao abrir o app, informe suas credenciais.
- O aplicativo armazena tokens e dados do usuário de forma segura.
- Se o login falhar, uma mensagem de erro é exibida e você permanece na tela de login.

### 3.2. Cadastro de Produto

- Acesse “Cadastrar Novos Produtos” pelo menu admin ou pelos cartões do menu principal.
- Preencha o formulário:
  - Nome, descrição, fornecedor, tipo de item, estoque mínimo/máximo, data de validade (se aplicável).
- Para admins, a seção padrão pode vir pré-selecionada (ex: Almoxarifado).
- Envie o formulário para cadastrar o produto.

### 3.3. Gestão de Estoque

- Consulte os produtos navegando até o estoque.
- Pesquise, filtre ou atualize informações dos produtos conforme permissões do seu perfil.

### 3.4. Gestão de Perfil

- Visualize seu perfil e dados atuais.
- Troque sua senha ou faça logout pelas opções do perfil.

---

## 4. Perfis e Permissões

- **ADMIN**: Acesso total, pode cadastrar produtos, gerenciar usuários e seções.
- **Usuários Padrão**: Permissões limitadas (ex: visualizar produtos, editar apenas seu perfil).

---

## 5. Fluxo de Dados (Arquitetura)

- **presentation/**: Widgets de UI e navegação
- **controllers/**: Lógica de negócio e integração de APIs para UI
- **domain/**: Entidades, contratos e repositórios abstratos
- **data/**: Acesso a APIs, modelos de dados e implementação de repositórios
- **core/**: Utilitários para armazenamento seguro, temas e helpers

---

## 6. Boas Práticas

- Utilize componentes reutilizáveis para formulários e telas.
- Respeite os contratos de domínio ao implementar novas features.
- Use temas compartilhados para garantir UI consistente.
- Mantenha a separação de lógica entre as camadas para facilitar testes e escalabilidade.

---

## 7. Solução de Problemas

- Se a navegação falhar, confira as rotas em `routes/`.
- Para erros de API, verifique o backend e suas credenciais.
- Para problemas em desktop, confira as dependências nativas (veja o manual de instalação).

---

## 8. Mais Informações

- Para temas e estilos customizados, veja `core/theme/`.
- Para configurações avançadas (ex: CMake para Linux/Windows), consulte as pastas de plataforma.

---
