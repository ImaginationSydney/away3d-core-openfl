package away3d.stereo;

import openfl.events.Event;

/**
 * ...
 * @author P.J.Shand
 */
class StereoEvent extends Event
{
	public static inline var LEFT:String = "left";
	public static inline var RIGHT:String = "right";
	
	public function new(type:String, bubbles:Bool=false, cancelable:Bool=false) 
	{
		super(type, bubbles, cancelable);
		
	}
	
}