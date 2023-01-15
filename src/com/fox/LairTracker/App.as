import com.GameInterface.DistributedValueBase;
import com.GameInterface.Dynels;
import com.GameInterface.Game.CharacterBase;
import com.GameInterface.Game.Dynel;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.TeamInterface;
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
class com.fox.LairTracker.App
{
    private var m_swfRoot:MovieClip;
    private var WaypointSystem;

    public var TrackedDynels:Object;
    public var RaidDynels:Object;
    public var WatchedDynels:Object;
    static var TrackingList:Object;

    private var inRaid:Boolean;
    private var bruteForcing:Boolean;

    private var bruteForceTarget:Dynel;
    private var forceBruteForceCooldown:Number;
    private var bruteForceArray:Array;
    private var loaded:Boolean;

    public function App(root)
    {
        m_swfRoot = root;
        TrackingList = new Object();
        //lairs
        //KM
        TrackingList["7936503"] = true;
        //SC
        TrackingList["7944316"] = true;
        TrackingList["7944347"] = true;
        //BM
        TrackingList["7945256"] = true;//PICK THIS UP

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
        //Maize is 9368621,but it's not necessary
        //graffiti + "canvas"
        TrackingList["9396921"] = true;
        TrackingList["9400928"] = true;
        //water bucket
        TrackingList["9396919"] = true;
        //sheet metal
        TrackingList["9405973"] = true;
    }

    private function CheckIfInRaid()
    {
        inRaid = DistributedValueBase.GetDValue("LairTracker_AlwaysShowInRaid") ? TeamInterface.IsInRaid(CharacterBase.GetClientCharID()) : false;
    }
    public function OnLoad()
    {
        VicinitySystem.SignalDynelEnterVicinity.Connect(Track, this);
        Dynels.DynelGone.Connect(Untrack, this);
        WaypointSystem = _root.waypoints;
        WaypointInterface.SignalPlayfieldChanged.Connect(UntrackAll, this);
        TeamInterface.SignalClientJoinedRaid.Connect(CheckIfInRaid, this);
        TeamInterface.SignalClientLeftRaid.Connect(CheckIfInRaid, this);
    }

    public function OnUnload()
    {
        VicinitySystem.SignalDynelEnterVicinity.Disconnect(Track, this);
        Dynels.DynelGone.Disconnect(Untrack, this);
        m_swfRoot.onEnterFrame = undefined;
        WaypointInterface.SignalPlayfieldChanged.Disconnect(UntrackAll, this);
        TeamInterface.SignalClientJoinedRaid.Disconnect(CheckIfInRaid, this);
        TeamInterface.SignalClientLeftRaid.Disconnect(CheckIfInRaid, this);
    }

    public function onActivated()
    {
        if (!loaded)
        {
            loaded = true;
            UntrackAll();
            CheckIfInRaid();
            kickstart();
        }
    }

    //finds the dynels that were alredy loaded before i had chance to connect my signals
    private function kickstart()
    {
        var ls:WeakList = Dynel.s_DynelList;
        for (var num = 0; num < ls.GetLength(); num++)
        {
            var dyn:Character = ls.GetObject(num);
            Track(dyn.GetID());
        }
    }
    
    public function onDeactivated()
    {
        UntrackAll();
    }
    
    //Updates the drawn waypoints on each frame
    public function onFrame()
    {
        for (var stringID in WatchedDynels)
        {
            var dyn:Dynel = WatchedDynels[stringID];
            var id:ID32 = dyn.GetID();
            if ((ProjectUtilsBase.GetInteractionType(dyn.GetID()) != 0 || (inRaid && dyn.GetStat(12))) && 
                dyn.GetDistanceToPlayer() < DistributedValueBase.GetDValue("LairTracker_Range"))
            {
                Untrack(id.m_Type, id.m_Instance);
                Track(dyn.GetID(), true);
                CheckIfTracking();
            }
            else if(!dyn.GetDistanceToPlayer())
            {
                Untrack(id.m_Type, id.m_Instance);
            }
        }
        for (var stringID in TrackedDynels)
        {
            var dyn:Dynel = TrackedDynels[stringID];
            var id:ID32 = dyn.GetID();
            var scrPos:Point = dyn.GetScreenPosition();
            var waypoint = WaypointSystem.m_RenderedWaypoints[dyn.GetID()];
            var interactable = (id.GetType() == 51320) ? ProjectUtilsBase.GetInteractionType(id) : true;
            if (interactable == 0 || !dyn.GetDistanceToPlayer() || dyn.GetDistanceToPlayer() > DistributedValueBase.GetDValue("LairTracker_Range"))
            {
                // No need to add it to RaidDynels, WatchedDynels will take care of that
                Untrack(id.m_Type, id.m_Instance);
                WatchedDynels[stringID] = dyn;
                CheckIfTracking();
            }
            else
            {
                waypoint.m_Waypoint.m_ScreenPositionX = scrPos.x;
                waypoint.m_Waypoint.m_ScreenPositionY = scrPos.y;
                waypoint.m_Waypoint.m_DistanceToCam = dyn.GetCameraDistance(0);
                waypoint.Update(Stage.visibleRect.width);
                waypoint = undefined;
            }
        }
        for (var stringID in RaidDynels)
        {
            var dyn:Dynel = RaidDynels[stringID];
            if (!inRaid || !dyn.GetStat(12) || !dyn.GetDistanceToPlayer() || dyn.GetDistanceToPlayer() > DistributedValueBase.GetDValue("LairTracker_Range"))
            {
                Untrack(dyn.GetID().GetType(),dyn.GetID().GetInstance());
                WatchedDynels[stringID] = dyn;
                CheckIfTracking();
            }
            else
            {
                var waypoint = WaypointSystem.m_RenderedWaypoints[dyn.GetID()];
                var scrPos:Point = dyn.GetScreenPosition();
                waypoint.m_Waypoint.m_ScreenPositionX = scrPos.x;
                waypoint.m_Waypoint.m_ScreenPositionY = scrPos.y;
                waypoint.m_Waypoint.m_DistanceToCam = dyn.GetCameraDistance(0);
                waypoint.Update(Stage.visibleRect.width);
                waypoint = undefined;
            }
        }
    }

    private function inList(dyn:Dynel)
    {
        //com.GameInterface.UtilsBase.PrintChatText(dyn.GetName() + " " +dyn.GetStat(112));
        //if (dyn.IsGhosting() && !dyn.isClientChar()) return true; // Anima form tracking?
        return TrackingList[string(dyn.GetStat(112))];
    }

    private function BruteForceDynel()
    {
        var target:ID32 = ID32(bruteForceArray.pop());
        if ( target )
        {
            if ( TrackedDynels[target.toString()] || WatchedDynels[target.toString()] || RaidDynels[target.toString()])
            {
                BruteForceDynel();
                return;
            }
            var dynel:Dynel = Dynel.GetDynel(target);
            var label = inList(dynel);
            if ( label && dynel.GetDistanceToPlayer() < DistributedValueBase.GetDValue("LairTracker_Range"))
            {
                VicinitySystem.SignalDynelEnterVicinity.Emit(target, true);
            }
            setTimeout(Delegate.create(this, BruteForceDynel), 50);
        }
        else
        {
            bruteForcing = false;
        }
    }

    private function ForcedBoost()
    {
        if (bruteForceTarget) RangeBoost(bruteForceTarget.GetID());
    }

    private function RangeBoost(originalID:ID32):Void
    {
        if (!bruteForcing && DistributedValueBase.GetDValue("LairTracker_BoostEnabled"))
        {
            clearTimeout(forceBruteForceCooldown);
            forceBruteForceCooldown = setTimeout(Delegate.create(this, ForcedBoost), 10000);
            bruteForcing = true;
            var targets = 100;
            var delayMulti = 5;
            var originalInstance = originalID.GetInstance();
            bruteForceArray = [];
            for (var i = 0; i < targets; i++)
            {
                var id:ID32 = new ID32(originalID.GetType(), originalInstance + i - targets / 2);
                bruteForceArray.push(id);
            }
            BruteForceDynel();
        }
    }

    private function Track(id:ID32, noBoost:Boolean )
    {
        var stringID = id.toString();
        if (!noBoost && (WatchedDynels[stringID] || RaidDynels[stringID] || TrackedDynels[stringID]))
        {
            var dyn:Dynel = Dynel.GetDynel(id);
            bruteForceTarget = Dynel.GetDynel(id);
            return;
        }
        if (id.GetType() == 51320 || id.GetType() == 50000 )
        {
            var dyn:Dynel = Dynel.GetDynel(id);
            var label = inList(dyn);
            if (!label) return;
            if ( !noBoost){
                bruteForceTarget = dyn;
            }
            // Interactable or NPC
            var interactable = id.GetType() == 51320 ? ProjectUtilsBase.GetInteractionType(id) : true;
            // interactable or inraid and dynel has model(not picked yet)
            if (
                (interactable != 0 || (dyn.GetStat(12) && inRaid)) && 
                dyn.GetDistanceToPlayer() < DistributedValueBase.GetDValue("LairTracker_Range"))
            {
                var WPBase:Waypoint = new Waypoint();
                if (interactable != 0)
                {
                    TrackedDynels[stringID] = dyn;
                    WPBase.m_Color = 0xFF0000;
                }
                else
                {
                    RaidDynels[stringID] = dyn;
                    WPBase.m_Color = 0xFFFFFF;
                }
                WPBase.m_WaypointType = _global.Enums.WaypointType.e_RMWPScannerBlip;
                WPBase.m_WaypointState = _global.Enums.QuestWaypointState.e_WPStateActive;
                WPBase.m_IsScreenWaypoint = true;
                WPBase.m_IsStackingWaypoint = true;
                WPBase.m_Radius = 0;
                WPBase.m_CollisionOffsetX = 0;
                WPBase.m_CollisionOffsetY = 0;
                WPBase.m_MinViewDistance = 0;
                WPBase.m_MaxViewDistance = DistributedValueBase.GetDValue("LairTracker_Range");
                WPBase.m_Id = id;
                if (label == true) WPBase.m_Label = dyn.GetName();
                else WPBase.m_Label = label;
                WPBase.m_WorldPosition = dyn.GetPosition(0);
                var scrPos:Point = dyn.GetScreenPosition();
                WPBase.m_ScreenPositionX = scrPos.x;
                WPBase.m_ScreenPositionY = scrPos.y;
                WPBase.m_DistanceToCam = dyn.GetCameraDistance(0);
                WaypointSystem.m_CurrentPFInterface.m_Waypoints[stringID] = WPBase;
                WaypointSystem.m_CurrentPFInterface.SignalWaypointAdded.Emit(WPBase.m_Id);
            }
            //keep chekcing if the item becomes interactable or (player is in raid and item has a model)
            else
            {
                WatchedDynels[stringID] = dyn;
            }
            m_swfRoot.onEnterFrame = Delegate.create(this, onFrame);
            RangeBoost(id);
        }
    }

    private function Untrack(type:Number, instance:Number)
    {
        var id:ID32 = new ID32(type, instance);
        var stringID = id.toString();
        var changed:Boolean = false;
        if (TrackedDynels[stringID])
        {
            delete TrackedDynels[stringID]
            delete WaypointSystem.m_CurrentPFInterface.m_Waypoints[stringID];
            WaypointSystem.m_CurrentPFInterface.SignalWaypointRemoved.Emit(id);
        }
        if (RaidDynels[stringID])
        {
            delete RaidDynels[stringID]
            delete WaypointSystem.m_CurrentPFInterface.m_Waypoints[stringID];
            WaypointSystem.m_CurrentPFInterface.SignalWaypointRemoved.Emit(id);
        }
        if (WatchedDynels[stringID])
        {
            delete WatchedDynels[stringID];
        }
        CheckIfTracking();
    }
    
    private function CheckIfTracking():Void 
    {
        m_swfRoot.onEnterFrame = undefined;
        for (var i in TrackedDynels)
        {
            m_swfRoot.onEnterFrame = Delegate.create(this, onFrame);
            return;
        }
        for (var i in RaidDynels)
        {
            m_swfRoot.onEnterFrame = Delegate.create(this, onFrame);
            return;
        }
        for (var i in WatchedDynels)
        {
            m_swfRoot.onEnterFrame = Delegate.create(this, onFrame);
            return;
        }
    }

    private function UntrackAll()
    {
        m_swfRoot.onEnterFrame = undefined;
        WatchedDynels = new Object();
        for (var stringID in TrackedDynels)
        {
            delete WaypointSystem.m_CurrentPFInterface.m_Waypoints[stringID];
            WaypointSystem.m_CurrentPFInterface.SignalWaypointRemoved.Emit(TrackedDynels[stringID].GetID());
        }
        for (var stringID in RaidDynels)
        {
            delete WaypointSystem.m_CurrentPFInterface.m_Waypoints[stringID];
            WaypointSystem.m_CurrentPFInterface.SignalWaypointRemoved.Emit(RaidDynels[stringID].GetID());
        }
        TrackedDynels = new Object();
        RaidDynels = new Object();
        clearTimeout(forceBruteForceCooldown);
        bruteForceArray = [];
        bruteForceTarget = undefined;
        bruteForcing = false;
        loaded = false;
    }
}