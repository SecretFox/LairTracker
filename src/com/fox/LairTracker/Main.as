import com.Utils.Archive;
import com.fox.LairTracker.App;

class com.fox.LairTracker.Main
{
	private static var s_app:App;

	public static function main(swfRoot:MovieClip):Void{
		s_app = new App(swfRoot);
		
		swfRoot.onLoad = OnLoad;
		swfRoot.OnUnload = OnUnload;
		swfRoot.OnModuleActivated = OnActivated;
		swfRoot.OnModuleDeactivated = OnDeactivated;
	}
	
	public function Main(){ }
	public static function OnLoad(){
		s_app.OnLoad();
	}	

	public static function OnUnload():Void{
		s_app.OnUnload();
	}	

	public static function OnActivated(){
		s_app.onActivated();
	}
	
	public static function OnDeactivated(){		
		s_app.onDeactivated();
	}
}