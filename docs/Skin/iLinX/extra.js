// Additional useful functions for custom HTML pages

iLinX.stopDefault = function( evt )
{
  evt.preventDefault();
};

iLinX.disableDefaultBehavior = function()
{
  var body = document.getElementsByTagName( "body" ).item( 0 );

  body.onmousedown = iLinX.stopDefault;
  body.ontouchstart = iLinX.stopDefault;
  body.ontouchmove = iLinX.stopDefault;
  body.ontouchend = iLinX.stopDefault;
  body.ontouchcancel = iLinX.stopDefault;
  body.onmouseup = iLinX.stopDefault;
  body.ongesturestart = iLinX.stopDefault;
  body.ongesturechange = iLinX.stopDefault;
  body.ongestureend = iLinX.stopDefault;
};
