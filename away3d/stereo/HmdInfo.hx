package away3d.stereo;

import openfl.Vector;

/**
 * ...
 * @author P.J.Shand
 */
class HmdInfo
{
	public var chromaAbCorrection:Vector<Float>;
	public var distortionK:Vector<Float>;
	public var eyeToScreenDistance:Float;
	public var hResolution:Int;
	public var hScreenSize:Float;
	public var interPupillaryDistance:Float;
	public var lensSeparationDistance:Float;
	public var vResolution:Int;
	public var vScreenCenter:Float;
	public var vScreenSize:Float;
	
	public function new() 
	{
		
	}
	
}