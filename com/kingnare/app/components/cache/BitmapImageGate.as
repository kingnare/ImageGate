package com.kingnare.app.components.cache
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.events.DynamicEvent;
	
	import spark.primitives.BitmapImage;
    
    [Event(name="cacheAdd", type="mx.events.DynamicEvent")]
    
	public class BitmapImageGate extends BitmapImage
    {
		
		private var _urlRequest			: URLRequest;
		private var _urlLoader			: URLLoader;
		private var _loader				 :Loader;
		private var _fileStream			: FileStream;
		
		private var _url				: String;
		private var _filename			: String;
		private var _file				: File;
		
		private var _assetURL			: String;
		
		private var _localFolder		: String;
        private var _cache:Boolean;
		
		public function BitmapImageGate()
        {
			super();
		}
		
		public function findImage():void 
        {
            if(!_cache && _assetURL!=null)
            {
                source = _assetURL;
                return;
            }
            
			/**
			 * 	The _localFolder must be set in order to proceed.
			 */
			if( _localFolder == null ) 
            {
				return;
			}
			
			
			/**
			 * 	If we don't have either of the _assetURL or all of the 
			 * 	multi-screen URLs then we can not proceed.  
			 */
			if( _assetURL == null) 
            {
				return;
			}
			
			/**
			 * Check to see what the _url is going to be for this particular image.
			 *  -If _assetURL != null then use that url.
			 *  -Otherwise find the correct _url based on the current screen resolution.
			 */
			
			if( _assetURL != null ) 
            {
				_url = _assetURL;	
			} 
            this.source = null;
            
			_filename = _url.substring( _url.lastIndexOf( '/' ) + 1 );
			
			_file = File.cacheDirectory.resolvePath( _localFolder + '/' + _filename );
			//trace(_assetURL, _file.url, _file.nativePath);
			if( _file.exists ) 
            {
                this.source = _file.url;
                this.addEventListener(IOErrorEvent.IO_ERROR, onIOErrorHandler);
				/*var byteArray : ByteArray = new ByteArray();
				_fileStream = new FileStream();
				_fileStream.open( _file, FileMode.READ );
				_fileStream.readBytes( byteArray );
				_fileStream.close();
				_fileStream = null;
				_file 		= null;
				
				_loader = new Loader();
				_loader.contentLoaderInfo.addEventListener( Event.COMPLETE, onBytesLoaded );
				_loader.loadBytes( byteArray );*/
				
			} 
            else 
            {
				downloadRemoteFile();
			}
		}
		
        protected function onIOErrorHandler(event:IOErrorEvent):void
        {
            event.preventDefault();
            event.stopImmediatePropagation();
            this.removeEventListener(IOErrorEvent.IO_ERROR, onIOErrorHandler);
            
            if(_file.exists)
            {
                downloadRemoteFile();
            }
        }
        
		private function onBytesLoaded( e:Event ):void 
        {
			this.source = new Bitmap( e.target.content.bitmapData );
			_loader.contentLoaderInfo.removeEventListener( Event.COMPLETE, onBytesLoaded );
			
			// Cleanup
			_loader 	= null;
			_filename 	= null;
            
            this.dispatchEvent(new Event(Event.COMPLETE));
		}
		
		
		private function downloadRemoteFile():void 
        {
			_urlLoader					= new URLLoader();
			_urlRequest 				= new URLRequest( _url );
			_urlLoader.dataFormat 		= URLLoaderDataFormat.BINARY;
			_urlLoader.addEventListener( Event.COMPLETE, 		onDownloadComplete );
			_urlLoader.addEventListener( IOErrorEvent.IO_ERROR, onIOerror );
			_urlLoader.load( _urlRequest );
		}
		
		private function onDownloadComplete( e:Event ):void
        {
            if(!_urlLoader || _urlLoader.data == undefined)
                return;
            
            var byteArray : ByteArray 	= _urlLoader.data;
			_fileStream 				= new FileStream();
			_fileStream.open( _file, FileMode.WRITE );
			_fileStream.writeBytes( byteArray, 0, byteArray.length );
			_fileStream.close();	
            
            var sizeEvent:DynamicEvent = new DynamicEvent("cacheAdd");
            sizeEvent.data = byteArray.length;
            dispatchEvent(sizeEvent);
			
			_loader = new Loader();
			_loader.contentLoaderInfo.addEventListener( Event.COMPLETE, onBytesLoaded );
			_loader.loadBytes( byteArray );
			
			// Cleanup
            _urlLoader.removeEventListener( Event.COMPLETE, 		onDownloadComplete );
            _urlLoader.removeEventListener( IOErrorEvent.IO_ERROR, onIOerror );
			_urlLoader.close();
			_urlLoader 	= null;
			_fileStream = null;
			_urlRequest = null;
			_url		= null;
		}
        
        public function stop():void
        {
            try
            {
                _urlLoader.close(); 
            } 
            catch(error:Error) 
            {
                
            } 
        }
        
		private function onIOerror( e:IOErrorEvent ):void 
        {
			trace( "image download error : " + _url + " : " + _filename );
			
			// Cleanup
            _urlLoader.removeEventListener( Event.COMPLETE, 		onDownloadComplete );
            _urlLoader.removeEventListener( IOErrorEvent.IO_ERROR, onIOerror );
			_urlLoader.close();
			_urlLoader 	= null;
			_fileStream = null;
			_filename 	= null;
		}
		
		/*	************************************************************
		*	Setters
		*	************************************************************ */
		public function set assetURL( value:String ):void
        {
			if( _assetURL == value ) 
            {
				return;
			}
			_assetURL = value;
			
			findImage();
		}
		
		
		public function set localFolder( value:String ):void 
        {
			if( _localFolder == value ) 
            {
				return;
			}
			
			_localFolder = value;
			
			findImage();
		}

		/*	************************************************************
		*	Getters
		*	************************************************************ */
		public function get assetURL():String { return _assetURL; }
		public function get localFolder():String { return _localFolder; }

        public function get cache():Boolean
        {
            return _cache;
        }
        
        [Bindable]
        public function set cache(value:Boolean):void
        {
            _cache = value;
        }

	}
}