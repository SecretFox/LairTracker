import com.GameInterface.Game.Dynel;
import com.GameInterface.Game.Character;
import com.GameInterface.ProjectUtilsBase;
import com.GameInterface.VicinitySystem;
import com.Utils.ID32;
import com.Utils.WeakList;
import flash.geom.Point;
import mx.utils.Delegate;
import com.GameInterface.Waypoint;
import com.GameInterface.WaypointInterface;
/**
 * ...
 * @author fox
 */
class com.fox.LairTracker.App {
	private var m_swfRoot:MovieClip;
	private var m_Player:Character
	private var TrackedDynels:Object;
	private var WaypointSystem;
	static var TrackedObjects:Object;

	public function App(root) {
		m_swfRoot = root
	}

	public function onFrame() {
		for (var idx in TrackedDynels) {
			var dyn:Dynel = TrackedDynels[idx];
			if (ProjectUtilsBase.GetInteractionType(dyn.GetID()) == 0){
				Untrack(dyn.GetID());
			}
			var scrPos:Point = dyn.GetScreenPosition();
			var waypoint = WaypointSystem.m_RenderedWaypoints[dyn.GetID()];
			waypoint.m_Waypoint.m_ScreenPositionX = scrPos.x;
			waypoint.m_Waypoint.m_ScreenPositionY = scrPos.y;
			waypoint.m_Waypoint.m_DistanceToCam = dyn.GetCameraDistance(0);
			waypoint.Update(Stage.visibleRect.width);
			waypoint = undefined;
		}
	}

	public function OnLoad() {
		m_Player = Character.GetClientCharacter();
		VicinitySystem.SignalDynelEnterVicinity.Connect(Track, this);
		VicinitySystem.SignalDynelLeaveVicinity.Connect(Untrack, this);
		WaypointSystem = _root.waypoints;
		WaypointInterface.SignalPlayfieldChanged.Connect(UntrackAll, this);
		TrackedObjects = new Object();
		//KM
		TrackedObjects["7936503"] = true;
		//SC
		TrackedObjects["7944316"] = true;
		TrackedObjects["7944347"] = true;
		//BM
		TrackedObjects["7945224"] = "1st Ward stone";
		TrackedObjects["7945225"] = "2nd Ward stone";
		TrackedObjects["7945226"] = "3rd Ward stone";
		TrackedObjects["7945227"] = "4th Ward stone";
		TrackedObjects["7945228"] = "5th Ward stone";
		TrackedObjects["7945229"] = "6th Ward stone";
		//SD
		TrackedObjects["7929136"] = true;
		TrackedObjects["7929138"] = true;
		//CotSG
		TrackedObjects["7945562"] = true;
		TrackedObjects["7945563"] = true;
		TrackedObjects["7945561"] = true;
		TrackedObjects["7929477"] = true;
		//BF
		TrackedObjects["7877092"] = "Broken piece";
		TrackedObjects["7877040"] = true;
		TrackedObjects["7877091"] = true;
		//SF
		TrackedObjects["7912109"] = true;
		TrackedObjects["7863152"] = "Barrel";
		//CF
		TrackedObjects["7945479"] = true;
		TrackedObjects["7945485"] = true;
		TrackedObjects["7945486"] = true;
		TrackedObjects["7945487"] = true;
		TrackedObjects["7945476"] = true;
		//Misc
		TrackedObjects["9265030"] = "C4";
		TrackedObjects["9265009"] = "C4";
		TrackedObjects["5981406"] = true;
		TrackedObjects["5981403"] = true;
		TrackedObjects["5981422"] = true;
		TrackedObjects["5981414"] = true;
	}

	public function OnUnload() {
		VicinitySystem.SignalDynelEnterVicinity.Disconnect(Track, this);
		VicinitySystem.SignalDynelLeaveVicinity.Disconnect(Untrack, this);
		m_swfRoot.onEnterFrame = undefined;
		WaypointInterface.SignalPlayfieldChanged.Disconnect(UntrackAll, this);
	}

	private function inList(dyn:Dynel) {
		return TrackedObjects[string(dyn.GetStat(112))];
	}
	
	private function Track(id:ID32) {
		var dyn:Dynel = new Dynel(id);
		if (id.GetType() == 51320) {
			var label = inList(dyn);
			/*	Checks if the item is interactable
			*	Downside is that you can't tell your raid members where items are located 
			* 	if you have already completed your quest, but on the plus side you no longer see items that you can't use anymore.
			*/
			var interactable = ProjectUtilsBase.GetInteractionType(dyn.GetID());
			if (label != undefined && interactable != 0	) {
				TrackedDynels[dyn.GetID().toString()] = dyn;
				var WPBase:Waypoint = new Waypoint();
				WPBase.m_WaypointType = _global.Enums.WaypointType.e_RMWPScannerBlip;
				WPBase.m_WaypointState = _global.Enums.QuestWaypointState.e_WPStateActive;
				WPBase.m_IsScreenWaypoint = true;
				WPBase.m_IsStackingWaypoint = true;
				WPBase.m_Radius = 0;
				WPBase.m_Color = 0xFF0000;
				WPBase.m_CollisionOffsetX = 0;
				WPBase.m_CollisionOffsetY = 0;
				WPBase.m_MinViewDistance = 0;
				WPBase.m_MaxViewDistance = 50;
				WPBase.m_Id = dyn.GetID();
				if (label == true) WPBase.m_Label = dyn.GetName();
				else WPBase.m_Label = label;
				WPBase.m_WorldPosition = dyn.GetPosition(0);
				var scrPos:Point = dyn.GetScreenPosition();
				WPBase.m_ScreenPositionX = scrPos.x;
				WPBase.m_ScreenPositionY = scrPos.y;
				WPBase.m_DistanceToCam = dyn.GetCameraDistance(0);
				WaypointSystem.m_CurrentPFInterface.m_Waypoints[WPBase.m_Id.toString()] = WPBase;
				WaypointSystem.m_CurrentPFInterface.SignalWaypointAdded.Emit(WPBase.m_Id);
				m_swfRoot.onEnterFrame = Delegate.create(this, onFrame);
			}
		}
	}

	private function Untrack(id:ID32) {
		if(TrackedDynels[id.toString()]){
			delete TrackedDynels[id.toString()]
			delete WaypointSystem.m_CurrentPFInterface.m_Waypoints[id.toString()];
			WaypointSystem.m_CurrentPFInterface.SignalWaypointRemoved.Emit(id.toString());
			var tracking = false;
			for (var str in TrackedDynels) {
				tracking = true;
				break
			}
			if (tracking) m_swfRoot.onEnterFrame = Delegate.create(this, onFrame);
			else m_swfRoot.onEnterFrame = undefined;
		}
	}

	private function UntrackAll() {
		for (var str in TrackedDynels) {
			var id:ID32 = TrackedDynels[str].GetID();
			delete WaypointSystem.m_CurrentPFInterface.m_Waypoints[id.toString()];
			WaypointSystem.m_CurrentPFInterface.SignalWaypointRemoved.Emit(id.toString());
		}
		TrackedDynels = new Object();
		m_swfRoot.onEnterFrame = undefined;
	}

	//finds the dynels that were alredy loaded before i had time to connect my signals
	private function kickstart() {
		var ls:WeakList = Dynel.s_DynelList
		for (var num = 0; num < ls.GetLength(); num++) {
			var dyn:Character = ls.GetObject(num);
			Track(dyn.GetID());
		}
	}
	
	public function onActivated() {
		TrackedDynels = new Object();
		m_swfRoot.onEnterFrame = undefined;
		kickstart();
	}
	
	public function onDeactivated() {
		UntrackAll();
	}
}