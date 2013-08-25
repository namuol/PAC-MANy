require [
  'MyApp'
  'combo/web/WebApp'
], (
  MyApp
  WebApp
) ->

  app = new (MyApp(WebApp))('container')
  
  window.app = app
  app.run()
