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
o.window({ class = "^(openbot)$", float = true }, {
  pin = true,
  no_shadow = true,
  border_size = 0,
  no_blur = true,
  rounding = 0,
  no_dim = true,
  no_anim = true,
})
