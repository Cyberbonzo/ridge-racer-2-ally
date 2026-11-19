# Ridge Racer 2 no ROG Ally com Bazzite

Integração do Ridge Racer 2 europeu de PSP (UCES-00422) com a biblioteca Steam no Bazzite. A versão 0.1.0 usa o núcleo Linux x86-64 específico do jogo distribuído pelo Nimbus Alpha 2.2.1. O jogo e o Nimbus são fornecidos pelo jogador.

## Instalação

1. Coloque os arquivos deste projeto em `~/Games/RidgeRacer2`. Crie a subpasta `media` e coloque sua própria ISO europeia nela com o nome `disc.iso`.
2. Baixe o executável Linux oficial da [versão Alpha 2.2.1 do Nimbus](https://github.com/thebabyhippo303/nimbus-recompilation-project/releases/tag/alpha-2.2.1) e salve-o na pasta do projeto como `Nimbus.run`.
3. Conceda permissão de execução com `chmod +x Nimbus.run jogar.sh preparar.sh`. Abra o Nimbus, leia os termos e, caso concorde, registre seu aceite. Execute `./Nimbus.run --game UCES00422 --iso "$PWD/media/disc.iso"` para que o Nimbus extraia os componentes desta edição.
4. Execute `./preparar.sh`. O script verifica a ISO, o pacote e os quatro componentes do runtime com SHA-256. Se o lançador do Nimbus mostrar “SHA-256 is unavailable” após a extração no Bazzite, o script faz a verificação local com `sha256sum`.
5. Adicione `jogar.sh` como jogo externo na Steam, selecione **1920 × 1080** nas propriedades do atalho e abra pelo Modo Jogo do Bazzite. Use a execução Linux direta.

## Controles e vídeo

RT aciona o acelerador e LT aciona o freio no esquema padrão do jogo. Os pedais da edição de PSP são digitais. O analógico esquerdo dirige e o botão A confirma nos menus. O mapeamento SDL pertence a este atalho e foi preparado para o controle integrado que o Bazzite apresenta como Xbox One Elite 2.

O renderizador Vulkan usa escala interna 4×. A janela de apresentação ocupa 1920 × 1080 com a proporção original preservada. A corrida em Seaside Route 765 foi observada a aproximadamente 60 FPS no Ally.

## Progresso

O jogo usa o mesmo cartão de memória local em cada inicialização. O progresso gravado fica em `profile/PSP/SAVEDATA/UCES00422/`. Para fazer um backup, feche o jogo e copie essa pasta. Os registros de execução ficam em `logs/game.log`.
