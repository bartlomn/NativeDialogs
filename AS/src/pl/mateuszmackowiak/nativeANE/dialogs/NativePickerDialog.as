package pl.mateuszmackowiak.nativeANE.dialogs
{
	import flash.events.Event;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	
	import pl.mateuszmackowiak.nativeANE.nativeDialogNamespace;
	import pl.mateuszmackowiak.nativeANE.dialogs.support.AbstractNativeDialog;
	import pl.mateuszmackowiak.nativeANE.dialogs.support.PickerList;
	import pl.mateuszmackowiak.nativeANE.events.NativeDialogEvent;
	import pl.mateuszmackowiak.nativeANE.events.NativeDialogListEvent;

	use namespace nativeDialogNamespace
	
	public class NativePickerDialog extends AbstractNativeDialog
	{
		/**
		 * Uses the traditional (pre-Holo) alert dialog theme.
		 * <br>Constant Value: 1 (0x00000001)
		 */
		public static const DEFAULT_THEME:int = 0x00000001;
		//---------------------------------------------------------------------
		//
		// Private Static Properties.
		//
		//---------------------------------------------------------------------
		/**
		 * @private
		 */
		private static var _defaultTheme:uint = DEFAULT_THEME;
		//---------------------------------------------------------------------
		//
		// private properties.
		//
		//---------------------------------------------------------------------
		/**@private*/
		private var _theme:int = -1;
		/**@private*/
		private var _buttons:Vector.<String>=null;
		private var _width:Number = 300;
		private var _locked:Boolean = false;
		private var _dataProvider:Vector.<PickerList> = null;
		
		public function NativePickerDialog(theme:int=-1)
		{
			super(abstractKey);
			if(!isNaN(theme) && theme>-1)
				_theme = theme;
			else
				_theme = _defaultTheme;
		}
		
		/**@private*/
		override protected function init():void{
			try{
				_context = ExtensionContext.createExtensionContext(NativeAlertDialog.EXTENSION_ID, "PickerDialogContext");
				_context.addEventListener(StatusEvent.STATUS, onStatus);
			}catch(e:Error){
				showError("Error initiating contex of the PickerDialogContext extension: "+e.message,e.errorID);
			}
		}
		
		
		
		nativeDialogNamespace function setSelectedIndex(pickerList:PickerList, index:int):void{
			try{
				if(!isShowing()){
					return;
				}
				var p:PickerList;
				var pickerListIndex:int = -1;
				const len:uint = _dataProvider.length;
				for (var i:int = 0; i < len; i++) 
				{
					p = _dataProvider[i];
					if(p == pickerList){
						pickerListIndex = i;
					}
				}
				if(pickerListIndex ==-1){
					return;
				}
				_context.call("setSelectedIndex",pickerListIndex, index);
			}catch(e:Error){
				showError("Error calling setSelectedIndex function: "+e.message,e.errorID);
			}
		}
		
		
		/**
		 * Shows the dialog.
		 * 
		 * @param cancelable if pressing outside the dialog or the back button hides the dialog
		 * 
		 * @event pl.mateuszmackowiak.nativeANE.events.NativeDialogEvent.CLOSED
		 * pl.mateuszmackowiak.nativeANE.events.NativeDialogEvent.CANCELED
		 * pl.mateuszmackowiak.nativeANE.events.NativeDialogEvent.OPENED
		 * 
		 * @throws Error if the call was unsuccessful. Or will dispatch an Error Event.ERROR if there is a listener.
		 */
		public function show(cancelable:Boolean = true):Boolean
		{
			try{
				if(!_dataProvider){
					showError("dataProvider can't be empty while showing");
					return false;
				}
				
				if(!_buttons || _buttons.length==0){
					_buttons = Vector.<String>(["OK"]);
				}
				if(_buttons.length==1 && cancelable && isIOS())
				{
					_buttons.push("Cancel");
				}
				const leng:uint = _dataProvider.length;
				
				var data:Vector.<Vector.<String>> = new Vector.<Vector.<String>>(leng);
				var indexes:Vector.<int> = new Vector.<int>(leng);
				var widths:Vector.<Number> = new Vector.<Number>(leng);
				var p:PickerList;
				var autoResize:Boolean = true;
				for (var i:int = 0; i < leng; i++) 
				{
					p = _dataProvider[i];
					p.dialog = this;
					data[i] = p.getLabels();
					indexes[i] = p.selectedIndex;
					widths[i] = p.width;
					if(p.hadSetWidth){
						autoResize = false;
					}
				}
				if(autoResize){
					var w:Number = 300 / leng;
					for (i = 0; i < leng; i++) 
					{
						p = _dataProvider[i];
						p.setWidth(w);
						widths[i] = w;
					}
				}
				
				
				if(isIOS()){
					_context.call("show",_title,_message,_buttons, data, indexes,widths,cancelable, _theme);
				}
				return true;
			}catch(e:Error){
				showError("While calling show method: "+e.message,e.errorID);
			}
			return false;
		}
		
		
		
		public function set dataProvider(value:Vector.<PickerList>):void
		{
			if(_locked){
				return;
			}
			var p:PickerList;
			var len:uint;
			if(_dataProvider){
				len = _dataProvider.length;
				for (var i:int = 0; i < len; i++) 
				{
					p = _dataProvider[i];
					p.dialog = null;
				}
			}
			_dataProvider = value;
		}
		/**
		 * @private
		 */
		public function get dataProvider():Vector.<PickerList>
		{
			return _dataProvider;
		}
		
		
		/**
		 * List of button labels in the dialog.
		 * (if isShowing will be ignored until next call of the <code>show</code> method.)
		 */
		public function set buttons(value:Vector.<String>):void
		{
			_buttons = value;
		}
		/**
		 * @private
		 */
		public function get buttons():Vector.<String>
		{
			return _buttons;
		}
		
		
		//---------------------------------------------------------------------
		//
		// STATIC Content
		//
		//---------------------------------------------------------------------
		/**@private*/
		public static function set defaultTheme(value:int):void
		{
			_defaultTheme = value;
		}
		/**
		 * The default theme of all dialogs
		 * @default pl.mateuszmackowiak.nativeANE.dialogs.NativeDatePickerDialog#DEFAULT_THEME
		 */
		public static function get defaultTheme():int
		{
			return _defaultTheme;
		}
		
		
		/**
		 * Whether the extension is available on the device (<code>true</code>);<br>otherwise <code>false</code>.
		 */
		public static function get isSupported():Boolean{
			if(isIOS()|| isAndroid())
				return true;
			else 
				return false;
		}
		
		
		override public function dispose():void{
			
			if(_dataProvider){
				var p:PickerList;
				const len:uint = _dataProvider.length;
				for (var i:int = 0; i < len; i++) 
				{
					p = _dataProvider[i];
					p.dialog = null;
				}
			}
			super.dispose();
		}
		/*
		private function set width(value:Number):void{
			if(isShowing()){
				return;
			}
			_width = value;
		}
		private function get width():Number
		{
			return _width;
		}*/
		//---------------------------------------------------------------------
		//
		// Private Methods.
		//
		//---------------------------------------------------------------------
		private function dispatchChange(picker:PickerList , index:int):void
		{
			if (picker.hasEventListener(NativeDialogListEvent.LIST_CHANGE))
				picker.dispatchEvent(new NativeDialogListEvent(NativeDialogListEvent.LIST_CHANGE, index,true));
			if(hasEventListener(Event.CHANGE)){
				dispatchEvent(new Event(Event.CHANGE));
			}
		}
		
		/**
		 * @private
		 */
		private function onStatus( event : StatusEvent ) : void
		{
			event.stopImmediatePropagation();
			if(event.code==NativeDialogEvent.OPENED){
				_isShowing = true;
				if(hasEventListener(NativeDialogEvent.OPENED)){
					dispatchEvent(new NativeDialogEvent(NativeDialogEvent.OPENED,event.level));
				}
			}
			else if( event.code == 'log') {
				trace(event.level);
			}else if(event.code == NativeDialogListEvent.LIST_CHANGE){
				var picker:PickerList;
				var index:int = -1;
				if(event.level.indexOf("_")>-1){
					const args:Array = event.level.split("_");
					picker = _dataProvider[int(args[0])];
					index = int(args[1]);
					picker.selectedIndex = index;
				} else {
					picker = _dataProvider[0];
					index = int(event.level);
					picker.selectedIndex = index;
				}
				dispatchChange(picker,index);
			}
			else if( event.code == NativeDialogEvent.CLOSED)
			{
				_isShowing = false;
				if(hasEventListener(NativeDialogEvent.CLOSED))
					dispatchEvent(new NativeDialogEvent(NativeDialogEvent.CLOSED,event.level));
				
			}else if(event.code == NativeDialogEvent.CANCELED){
				_isShowing = false;
				if(hasEventListener(NativeDialogEvent.CANCELED))
					dispatchEvent(new NativeDialogEvent(NativeDialogEvent.CANCELED,event.level));
			}
			else{
				showError(event);
			}
		}
	}
	
	
}