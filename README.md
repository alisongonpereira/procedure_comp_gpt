# Echoes of Everchange

Echoes of Everchange é um RPG 2D procedural desenvolvido em Godot 4, criado para a ARENA IA. Cada mundo é gerado a partir de uma seed, alterando mapa, NPCs, itens, minibosses e o chefe final – apenas o jogador mantém as memórias entre as runas.

## Características

- **Mapa procedural** com ruído simplex, chance de mundo corrompido e regras invertidas.
- **NPCs persistentes** com falas dinâmicas e reputação básica via memória do jogador.
- **Combate rápido** por turno simplificado contra minibosses e chefe final.
- **Diário de memórias** que registra as últimas sementes jogadas, motivações e eventos marcantes.
- **Loja procedural** com estoque e preços dependentes da seed.
- **Música ambiente procedural** gerada em tempo real com base na seed e corrupção do mundo.

## Estrutura do projeto

```
project.godot            # Configuração principal do projeto Godot 4
src/
  main/                  # Cena principal e orquestração do jogo
  world/                 # Gerador procedural e diário
  entities/              # Scripts de Player, NPC e Enemy
  ui/                    # HUD e controles de interface
assets/                  # Reservado para futuras artes/áudios
data/
  sample_world_log.json  # Exemplo de log gerado
  diaries/               # Pasta sugerida para exportar diários (vazia inicialmente)
docs/
  demo_run.md            # Demonstração textual de uma run
```

Arquivos criados em tempo de execução são gravados na pasta `user://` do Godot:

- `user://diary.json` – diário persistente das runs.
- `user://last_world.json` – log detalhado do último mundo gerado.

## Requisitos

- Godot Engine 4.1+ (testado com 4.2).
- Para exportar para Android:
  - Android SDK & NDK (instalados conforme documentação do Godot).
  - Java JDK 11.
  - Build template Android instalado pelo Godot (`Project > Install Android Build Template`).

## Executando no desktop

1. Abra o Godot 4 e importe a pasta `procedure_comp_gpt` como projeto.
2. Execute a cena principal (`src/main/Main.tscn`).
3. Insira uma seed (ou deixe em branco para aleatória) e pressione **Entrar**.
4. Movimente-se com WASD ou setas, interaja com `E`, ataque com barra de espaço e abra o diário com TAB.

## Exportando para Android

1. Abra o projeto no Godot 4.
2. Instale o **Android Build Template** (caso ainda não esteja presente).
3. Configure `Editor > Editor Settings > Export > Android` com caminhos do SDK/NDK/Jarsigner.
4. Em **Project > Export**, adicione um preset Android.
5. Marque "Export With Debug" para builds de teste ou configure sua keystore para release.
6. Clique em **Export Project** para gerar o APK/AAB.

Com o template instalado, é possível usar `godot --headless --export-release Android build/everchange.apk` para exportar via linha de comando (ajuste o preset de export conforme o nome escolhido).

## Buildozer (alternativa)

Caso prefira embalar via Python/Kivy/Buildozer, é recomendado utilizar o Godot-to-Android nativo acima. Contudo, o código-fonte foi organizado para permitir uma porta para Kivy caso desejado – os scripts estão isolados por domínio (`src/world`, `src/entities`, `src/ui`).

## Dados procedurais

- **Seeds raras** desbloqueiam itens lendários (`Fragmento de Eco`, `Flor da Memória`, etc.).
- **Minibosses** fixos por arquétipo, mas com estatísticas e localizações variáveis.
- **Mundo corrompido** (5% de chance) inverte regras de movimentação: gramados viram obstáculos e terrenos hostis ficam transitáveis.
- **Diário** mantém as últimas 10 runs, incluindo eventos climáticos e motivação do boss.

## Desenvolvimento futuro

- Expandir reputação com NPCs (o código já registra se lembram do jogador).
- Adicionar sprites personalizados nas pastas `assets/`.
- Exportar automaticamente os logs de run para `data/` durante build.

## Licença

Projeto disponibilizado para fins educacionais no contexto da ARENA IA. Utilize, modifique e aprenda! 😊
