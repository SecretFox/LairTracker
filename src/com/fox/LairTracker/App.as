import com.GameInterface.Game.CharacterBase;
import com.GameInterface.Game.Dynel;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.TeamInterface;
import com.GameInterface.ProjectUtilsBase;
import com.GameInterface.UtilsBase;
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
	private var TrackedDynels:Object;
	private var RaidDynels:Object;
	private var WaypointSystem;
	static var TrackingList:Object;
	private var Unuseable:Object;
	private var FrameCounter:Number = 0;
	private var inRaid:Boolean;

	public function App(root) {
		m_swfRoot = root;
	}

	private function IsInRaid() {
		inRaid = TeamInterface.IsInRaid(CharacterBase.GetClientCharID());
	}

	public function onFrame() {
		FrameCounter++;
		if (FrameCounter > 1000){
			IsInRaid();
			FrameCounter = 0;
		}
		for (var idx in TrackedDynels) {
			var dyn:Dynel = TrackedDynels[idx];
			var interactable = (dyn.GetID().GetType() == 51320) ? ProjectUtilsBase.GetInteractionType(dyn.GetID()):true;
			if (interactable == 0) {
				// No need to track it for RaidDynels, unseable tracking will take care of that 
				Untrack(dyn.GetID());
				Unuseable[dyn.GetID().toString()] = dyn;
			} else {
				var scrPos:Point = dyn.GetScreenPosition();
				var waypoint = WaypointSystem.m_RenderedWaypoints[dyn.GetID()];
				waypoint.m_Waypoint.m_ScreenPositionX = scrPos.x;
				waypoint.m_Waypoint.m_ScreenPositionY = scrPos.y;
				waypoint.m_Waypoint.m_DistanceToCam = dyn.GetCameraDistance(0);
				waypoint.Update(Stage.visibleRect.width);
				waypoint = undefined;
			}
		}
		for (var idx in RaidDynels) {
			var dyn:Dynel = RaidDynels[idx];
			if (!inRaid){
				Untrack(dyn.GetID());
				Unuseable[dyn.GetID().toString()] = dyn;
			}
			else{
				if (dyn.GetStat(12)) {
					var scrPos:Point = dyn.GetScreenPosition();
					var waypoint = WaypointSystem.m_RenderedWaypoints[dyn.GetID()];
					waypoint.m_Waypoint.m_ScreenPositionX = scrPos.x;
					waypoint.m_Waypoint.m_ScreenPositionY = scrPos.y;
					waypoint.m_Waypoint.m_DistanceToCam = dyn.GetCameraDistance(0);
					waypoint.Update(Stage.visibleRect.width);
					waypoint = undefined;
				} else {
					Untrack(dyn.GetID());
					Unuseable[dyn.GetID().toString()] = dyn;
				}
			}
		}
		for (var idx in Unuseable) {
			var dyn:Dynel = Unuseable[idx];
			//NPC's shouldnt get put on this list,so should only need to check interaction type.
			if (ProjectUtilsBase.GetInteractionType(dyn.GetID()) != 0 || (inRaid && dyn.GetStat(12))) {
				delete Unuseable[dyn.GetID().toString()];
				Track(dyn.GetID());
			}
		}
	}

	public function OnLoad() {
		VicinitySystem.SignalDynelEnterVicinity.Connect(Track, this);
		VicinitySystem.SignalDynelLeaveVicinity.Connect(Untrack, this);
		WaypointSystem = _root.waypoints;
		WaypointInterface.SignalPlayfieldChanged.Connect(UntrackAll, this);
		TrackingList = new Object();
		//lairs
		//KM
		TrackingList["7936503"] = true;
		//SC
		TrackingList["7944316"] = true;
		TrackingList["7944347"] = true;
		//BM
		TrackingList["7945224"] = "1st Ward stone";
		TrackingList["7945225"] = "2nd Ward stone";
		TrackingList["7945226"] = "3rd Ward stone";
		TrackingList["7945227"] = "4th Ward stone";
		TrackingList["7945228"] = "5th Ward stone";
		TrackingList["7945229"] = "6th Ward stone";
		//SD
		TrackingList["7929136"] = true;
		TrackingList["7929138"] = true;
		//CotSG
		TrackingList["7945562"] = true;
		TrackingList["7945563"] = true;
		TrackingList["7945561"] = true;
		TrackingList["7929477"] = true;
		//BF
		TrackingList["7877092"] = "Broken piece";
		TrackingList["7877040"] = true;
		TrackingList["7877091"] = true;
		//SF
		TrackingList["7912109"] = true;
		TrackingList["7863152"] = "Barrel";
		//CF
		TrackingList["7945479"] = true;
		TrackingList["7945485"] = true;
		TrackingList["7945486"] = true;
		TrackingList["7945487"] = true;
		TrackingList["7945476"] = true;
		//Misc
		//scenarios
		TrackingList["9265030"] = "C4";
		TrackingList["9265009"] = "C4";
		//supply crate
		TrackingList["33551"] = true;
		//mushrooms for Breakfast of Champignons
		TrackingList["5981406"] = true;
		TrackingList["5981403"] = true;
		TrackingList["5981422"] = true;
		TrackingList["5981414"] = true;
		//al-Merayah bomb mission
		TrackingList["5971505"] = true;
		//some orochi tower keycards
		TrackingList["9076194"] = true;
		TrackingList["9076197"] = true;
		TrackingList["8873224"] = true;
		TrackingList["9076195"] = true;
		TrackingList["9076196"] = true;
		TrackingList["8895315"] = true;
		TrackingList["8894863"] = true;
		TrackingList["8894864"] = true;
		TrackingList["8907638"] = true;

		//SA
		//Dead Drop
		TrackingList["9406780"] = true;

		//Maize,works,but not necessary
		//TrackingList["9368621"] = true;

		//graffiti + "canvas"
		TrackingList["9396921"] = true;
		TrackingList["9400928"] = true;
		//water bucket
		TrackingList["9396919"] = true;
	}

	public function OnUnload() {
		VicinitySystem.SignalDynelEnterVicinity.Disconnect(Track, this);
		VicinitySystem.SignalDynelLeaveVicinity.Disconnect(Untrack, this);
		m_swfRoot.onEnterFrame = undefined;
		WaypointInterface.SignalPlayfieldChanged.Disconnect(UntrackAll, this);
	}

	private function inList(dyn:Dynel) {
		//com.GameInterface.UtilsBase.PrintChatText(dyn.GetName() + " " +dyn.GetStat(112));
		return TrackingList[string(dyn.GetStat(112))];
	}

	private function Track(id:ID32) {
		var type = id.GetType();
		if (type == 51320 || type == 50000 ) {
			var dyn:Dynel = new Dynel(id);
			var label = inList(dyn);
			if (!label) return;
			
			// not 0 if item is interactable
			var interactable = (type == 51320) ? ProjectUtilsBase.GetInteractionType(dyn.GetID()):true;
			if (interactable != 0	) {
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
			//still track items if in raid and it has a model
			else if (dyn.GetStat(12)) {
				IsInRaid();
				if(inRaid){
					RaidDynels[dyn.GetID().toString()] = dyn;
					var WPBase:Waypoint = new Waypoint();
					WPBase.m_WaypointType = _global.Enums.WaypointType.e_RMWPScannerBlip;
					WPBase.m_WaypointState = _global.Enums.QuestWaypointState.e_WPStateActive;
					WPBase.m_IsScreenWaypoint = true;
					WPBase.m_IsStackingWaypoint = true;
					WPBase.m_Radius = 0;
					WPBase.m_Color = 0xFFFFFF;
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
			//keep chekcing if the item becomes interactable or (player is in raid and item has a model)
			else {
				Unuseable[dyn.GetID().toString()] = dyn;
				m_swfRoot.onEnterFrame = Delegate.create(this, onFrame);
			}
		}
	}

	private function Untrack(id:ID32) {
		if (TrackedDynels[id.toString()]) {
			delete TrackedDynels[id.toString()]
			delete WaypointSystem.m_CurrentPFInterface.m_Waypoints[id.toString()];
			WaypointSystem.m_CurrentPFInterface.SignalWaypointRemoved.Emit(id.toString());
		}
		if (RaidDynels[id.toString()]) {
			delete RaidDynels[id.toString()]
			delete WaypointSystem.m_CurrentPFInterface.m_Waypoints[id.toString()];
			WaypointSystem.m_CurrentPFInterface.SignalWaypointRemoved.Emit(id.toString());
		}
		if (Unuseable[id.toString()]) {
			delete Unuseable[id.toString()]
		}
		var tracking = false;
		for (var str in TrackedDynels) {
			tracking = true;
			break
		}
		for (var str in RaidDynels) {
			tracking = true;
			break
		}
		for (var str in Unuseable) {
			tracking = true;
			break
		}
		if (tracking) m_swfRoot.onEnterFrame = Delegate.create(this, onFrame);
		else m_swfRoot.onEnterFrame = undefined;

	}

	private function UntrackAll() {
		for (var str in TrackedDynels) {
			var id:ID32 = TrackedDynels[str].GetID();
			delete WaypointSystem.m_CurrentPFInterface.m_Waypoints[id.toString()];
			WaypointSystem.m_CurrentPFInterface.SignalWaypointRemoved.Emit(id.toString());
		}
		for (var str in RaidDynels) {
			var id:ID32 = RaidDynels[str].GetID();
			delete WaypointSystem.m_CurrentPFInterface.m_Waypoints[id.toString()];
			WaypointSystem.m_CurrentPFInterface.SignalWaypointRemoved.Emit(id.toString());
		}
		TrackedDynels = new Object();
		Unuseable = new Object();
		RaidDynels = new Object();
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
		IsInRaid();
		TrackedDynels = new Object();
		RaidDynels = new Object();
		Unuseable = new Object();
		TeamInterface.SignalClientJoinedRaid.Connect(IsInRaid, this);
		TeamInterface.SignalClientLeftRaid.Connect(IsInRaid, this);
		m_swfRoot.onEnterFrame = undefined;
		kickstart();
	}

	public function onDeactivated() {
		TeamInterface.SignalClientJoinedRaid.Disconnect(IsInRaid, this);
		TeamInterface.SignalClientLeftRaid.Disconnect(IsInRaid,this);
		UntrackAll();
	}
}