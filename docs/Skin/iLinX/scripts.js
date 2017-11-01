// The interface object between iLinX and the custom view HTML pages

var iLinX = { 
  // Public interface

  // The current status of the DigiLinX system
  status: null,

  selectProfile: function( profile )
  {
    this._sendCommands( "selectProfile( " + this._escape( profile ) + " )" );
  },

  selectLocation: function( location )
  {
    this._sendCommands( "selectLocation( " + this._escape( location ) + " )" );
  },

  selectService: function( service )
  {
    this._sendCommands( "selectService( " + this._escape( service ) + " )" );
  },

  selectSourceInCurrentLocation: function( source )
  {
    this._sendCommands( "selectSourceInCurrentLocation( " + this._escape( source ) + " )" );
  },

  selectSourceInLocation: function( location,  source )
  {
    this._sendCommands( "selectSourceInLocation( " + this._escape( location ) + ", " + this._escape( source ) + " )" );
  },

  runMacroInCurrentLocation: function( macro )
  {
    this._sendCommands( "runMacroInCurrentLocation( " + this._escape( macro ) + " )" );
  },

  runMacroInLocation: function( location, macro )
  {
    this._sendCommands( "runMacroInLocation( " + this._escape( location ) + ", " + this._escape( macro ) + " )" );
  },

  setStatusMask: function( mask )
  {
    this._sendCommands( "setStatusMask( " + mask + " )" );
  },

  goHome: function()
  {
    this._sendCommands( "goHome()" );
  },

  closeView: function()
  {
    this._sendCommands( "closeView()" );
  },

    // For users to override with functions if they want to be appraised of current status.
  pageLoaded: null,
  statusUpdated: null,

  // Internals

  _commandQueue: new Array(),
  _sendCommands: function()
  {
    for (var i = 0; i < arguments.length; ++i)
      this._commandQueue.push( arguments[i] );
    window.location = "ilinx://0/processCommands";
  },
  _getCommand: function()
  {
    return this._commandQueue.shift();
  },
  _pageLoaded: function()
  {
    if (typeof this.pageLoaded == "function")
      return this.pageLoaded();
    else
      return "";
  },
  _currentStatus: function( newStatus )
  {
    this.status = newStatus;
    if (typeof this.statusUpdated == "function")
      this.statusUpdated();
  },
  _escape: function( aStringOrNumber )
  {
    if (typeof aStringOrNumber == "string")
    {
      aStringOrNumber = aStringOrNumber.replace( /\\/g, "\\\\" );
      aStringOrNumber = aStringOrNumber.replace( /\r/g, "\\r" );
      aStringOrNumber = aStringOrNumber.replace( /\n/g, "\\n" );
      aStringOrNumber = aStringOrNumber.replace( /\t/g, "\\t" );
      aStringOrNumber = aStringOrNumber.replace( /\"/g, "\\\"" );
      aStringOrNumber = "\"" + aStringOrNumber + "\"";
    }

    return aStringOrNumber;
  }
};
