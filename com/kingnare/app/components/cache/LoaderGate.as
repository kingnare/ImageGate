package com.kingnare.app.components.cache
{
	import com.kingnare.app.data.DataCenter;
	import com.kingnare.app.data.UserAgents;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.utils.ByteArray;
	
	import mx.events.DynamicEvent;
	
    [Event(name="cacheAdd", type="mx.events.DynamicEvent")]
    
	public class LoaderGate extends Loader
    {
		private var _urlRequest			: URLRequest;
		private var _urlLoader			: URLLoader;
		private var _fileStream			: FileStream;
		
		private var _url				: String;
		private var _filename			: String;
		private var _file				: File;
		
		private var _assetURL			: String;
		
		private var _localFolder		: String;
        private var _cache:Boolean;
        private var _server:String;
		
		public function LoaderGate(server:String)
        {
			super();
            _server = server;
		}
		
		private function findImage():void
        {
            if(!_cache && _assetURL!=null)
            {
                this.load(new URLRequest(_assetURL));
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
            
			_filename = _url.substring( _url.lastIndexOf( '/' ) + 1 );
			_file = File.cacheDirectory.resolvePath( _localFolder + '/' + _filename );
			//trace(_file.url, _file.nativePath);
			if( _file.exists ) 
            {
                //this.source = _file.url;
                this.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
                this.load(new URLRequest(_file.url));
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
        
        protected function ioErrorHandler(event:IOErrorEvent):void
        {   
            event.preventDefault();
            event.stopImmediatePropagation();
            this.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            
            if(_file.exists)
            {
                downloadRemoteFile();
            }
        }
        
		private function onBytesLoaded( e:Event ):void 
        {
			this.contentLoaderInfo.removeEventListener( Event.COMPLETE, onBytesLoaded );
			// Cleanup
			_filename 	= null;
            dispatchEvent(new Event(Event.COMPLETE));
		}
        
		private function downloadRemoteFile():void 
        {
			_urlLoader					= new URLLoader();
			_urlRequest 				= new URLRequest( _url );
            try
            {
                _urlRequest.userAgent = UserAgents.GetRandomUserAgent();//"Mozilla/5.0";
            } 
            catch(error:Error) 
            {
                
            }
            //_urlRequest.contentType = HTTPRequestMessage.CONTENT_TYPE_FORM;
            //_urlRequest.contentType = "application/x-www-form-urlencoded";
            _urlRequest.requestHeaders = [new URLRequestHeader("Referer", _server)];
            //trace(_urlRequest.requestHeaders);
			_urlLoader.dataFormat 		= URLLoaderDataFormat.BINARY;
			_urlLoader.addEventListener( Event.COMPLETE, 		onDownloadComplete );
			_urlLoader.addEventListener( IOErrorEvent.IO_ERROR, onIOerror );
            _urlLoader.addEventListener(ProgressEvent.PROGRESS, onProgress);
			_urlLoader.load( _urlRequest );
		}
        
        protected function onProgress(event:ProgressEvent):void
        {
            dispatchEvent(event);
        }
        
		private function onDownloadComplete( e:Event ):void
        {
			var byteArray : ByteArray 	= _urlLoader.data;
            if(byteArray == null)
                return;
			_fileStream 				= new FileStream();
			_fileStream.open( _file, FileMode.WRITE );
			_fileStream.writeBytes( byteArray, 0, byteArray.length );
			_fileStream.close();	
            
            var sizeEvent:DynamicEvent = new DynamicEvent("cacheAdd");
            sizeEvent.data = byteArray.length;
            dispatchEvent(sizeEvent);
			
			this.contentLoaderInfo.addEventListener( Event.COMPLETE, onBytesLoaded );
			this.loadBytes( byteArray );
			
			// Cleanup
            _urlLoader.removeEventListener( Event.COMPLETE, onDownloadComplete );
            _urlLoader.removeEventListener( IOErrorEvent.IO_ERROR, onIOerror );
            _urlLoader.removeEventListener(ProgressEvent.PROGRESS, onProgress);
			_urlLoader.close();
			_urlLoader 	= null;
			_fileStream = null;
			_urlRequest = null;
			_url		= null;
		}
		
		private function onIOerror( e:IOErrorEvent ):void 
        {
			trace( "image download error : " + _url + " : " + _filename );
			
			// Cleanup
            _urlLoader.removeEventListener( Event.COMPLETE, 	   onDownloadComplete );
            _urlLoader.removeEventListener( IOErrorEvent.IO_ERROR, onIOerror );
            _urlLoader.removeEventListener(ProgressEvent.PROGRESS, onProgress);
			_urlLoader.close();
			_urlLoader 	= null;
			_fileStream = null;
			_filename 	= null;
            
            dispatchEvent(e.clone() as IOErrorEvent);
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
        
        public function set cache(value:Boolean):void
        {
            _cache = value;
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
    }
}