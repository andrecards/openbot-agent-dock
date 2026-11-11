-- Dock de agentes do OpenBot (borda direita, estilo dock do macOS).
--
-- O OpenBot desenha o dock numa janela própria: transparente, sem moldura e
-- flutuante. Sem regra, ela pertence ao workspace em que nasceu e fica atrás
-- das outras janelas. Com `pin` o dock aparece em todos os workspaces e é
-- desenhado acima das janelas comuns, que é o que ele precisa para funcionar
-- como o dock do Mac.
--
-- O match usa `float` para alcançar só as janelas flutuantes do app: a janela
-- principal do OpenBot não é flutuante e continua com o tiling normal.
--
-- `no_shadow` evita a sombra do compositor em volta de um painel transparente.
-- `border_size = 0` elimina a moldura padrão desenhada pelo Hyprland.
-- `no_blur = true` impede que o compositor aplique blur na área vazia da janela.
-- `rounding = 0` evita cantos arredondados fantasmas na janela transparente.
-- `no_dim = true` impede escurecimento quando a janela perde o foco.
-- `no_anim = true` desativa animações na janela transparente da dock.
-- `no_follow_mouse = true`: com input:follow_mouse = 1, passar o mouse dava foco ao
-- dock e cada troca de foco repintava a janela transparente (piscada preta). A regra
-- tira só o foco por hover; o clique continua focando, e o chat do dock aceita teclado.
-- `decorate = false`: o Hyprland trata o dock X11 como janela comum; sem isso, o modo de workspace
-- flutuante do Omarchy (Super+L) põe nele a barra de título do hyprbars.
o.window({ class = "^(openbot)$", float = true }, {
  pin = true,
  no_shadow = true,
  border_size = 0,
  no_blur = true,
  rounding = 0,
  no_dim = true,
  no_anim = true,
  no_follow_mouse = true,
  decorate = false,
})

-- Janela principal do OpenBot (a que não flutua): é ela que processa os cliques
-- do dock e alimenta o chat dele. Em um workspace fora da tela, o Hyprland para
-- de renderizá-la e o Chromium dela trava, e aí os bots do dock só respondiam no
-- workspace onde o OpenBot estava. `render_unfocused` mantém essa janela recebendo
-- quadros mesmo fora da tela.
o.window({ class = "^(openbot)$", float = false }, {
  render_unfocused = true,
})
