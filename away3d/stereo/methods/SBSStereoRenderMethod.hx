package away3d.stereo.methods;

import away3d.core.managers.RTTBufferManager;
import away3d.core.managers.Stage3DProxy;
import away3d.debug.Debug;
import openfl.Lib;
import openfl.display3D.Context3DProgramType;
import openfl.Vector;

class SBSStereoRenderMethod extends StereoRenderMethodBase {

    var _sbsData:Vector<Float>;
	var rttManager:RTTBufferManager;
	
    public function new() {
        super();
        _sbsData = Vector.ofArray( [ 5.0, 10.0, 15.0, 1.0, 10.0, 20.0, 30.0, 40.0 ] );
    }

    override public function activate(stage3DProxy:Stage3DProxy):Void {
		//if (_textureSizeInvalid) {
			
			rttManager = RTTBufferManager.getInstance(stage3DProxy);
			_textureSizeInvalid = false;
			
			// xPos is the left edge offset of the RTT.x in relation to the texture width 
			// (e.g. 800 view with 1024 texture - left edge offset = 112)
			var xPos : Float = (rttManager.renderToTextureRect.x / rttManager.textureWidth);
			var yPos : Float = (rttManager.renderToTextureRect.y / rttManager.textureHeight);
			
			
			//trace([rttManager.textureWidth, stage3DProxy.width, rttManager.textureWidth / stage3DProxy.width]);
			//trace([rttManager.textureWidth, Lib.current.stage.stageWidth, rttManager.textureWidth / stage3DProxy.width]);
			//trace([rttManager.textureHeight, stage3DProxy.height, rttManager.textureHeight / stage3DProxy.height]);
			// For the two image offsets, need to take into consideration that the RTT is a larger
			// texture than the view so need to apply offsets to both left/right views
			_sbsData[ 0] = 2;
			_sbsData[ 1] = rttManager.renderToTextureRect.width;
			_sbsData[ 2] = 1;
			_sbsData[ 3] = .5;

			_sbsData[ 4] = (0.5 - xPos) * 0.5; 
			_sbsData[ 5] = (0.5 - xPos) * -0.5; 
			_sbsData[ 6] = 0;
			_sbsData[ 7] = (0.5 - yPos) * 0.5;
			
			//_sbsData[ 8] = rttManager.textureWidth / stage3DProxy.width;
			//_sbsData[ 9] = rttManager.textureHeight / stage3DProxy.height;
			//_sbsData[10] = (rttManager.textureWidth - stage3DProxy.width) / rttManager.textureWidth / 2;
			//_sbsData[11] = (rttManager.textureHeight - stage3DProxy.height) / rttManager.textureHeight / 2;
			
			_sbsData[ 8] = rttManager.textureWidth / Lib.current.stage.stageWidth;
			_sbsData[ 9] = rttManager.textureHeight / Lib.current.stage.stageHeight;
			_sbsData[10] = (rttManager.textureWidth - Lib.current.stage.stageWidth) / rttManager.textureWidth / 2;
			_sbsData[11] = (rttManager.textureHeight - Lib.current.stage.stageHeight) / rttManager.textureHeight / 2;
		//}
					
        stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _sbsData, 3);
    }

    override public function deactivate(stage3DProxy:Stage3DProxy):Void {
        stage3DProxy.context3D.setTextureAt(2, null);
    }

    override public function getFragmentCode():String {
        return  "// TEST \n" +
				"mov ft0, v1						\n" +	// translate: ft0.x = ft0.x + (left offset); ft0.yzw = v1.yzw + 0;
				"add ft0, ft0, fc1.xzzz				\n" +	// translate: ft0.x = ft0.x + (left offset); ft0.yzw = v1.yzw + 0;
				"div ft0.xy, ft0.xy, fc2.xy			\n" + 
				"add ft0.xy, ft0.xy, fc2.zw			\n" + 
				"tex ft1, ft0, fs0 <2d,linear,nomip,repeat>\n" +	// ft1 = getColorAt(texture=fs0, position=ft0)
				
				"add ft7, v1, fc1.yzzz				\n" +	// translate: ft7.x = ft7.x - (right offset); ft7.yzw = v1.yzw + 0;
				"div ft7.xy, ft7.xy, fc2.xy			\n" + 
				"add ft7.xy, ft7.xy, fc2.zw			\n" + 
				"tex ft2, ft7, fs1 <2d,linear,nomip,repeat>\n" +	// ft2 = getColorAt(texture=fs1, position=ft7)
				
				"div ft3, v0.x, fc0.y 				\n" +	// ratio: get fraction of way across the screen (range 0-1, see next line)
				"frc ft3, ft3						\n" +	// ratio: ft3 = fraction(v0.x / renderWidth);
				"slt ft4, ft3, fc0.w 				\n" +	// ft4 = (ft3 < 0.5) ? 1 : 0;
				"sge ft5, ft3, fc0.w 				\n" +	// ft5 = (ft3 >= 0.5) ? 1 : 0;
				"mul ft4, ft2, ft4 					\n" +	// ft6 = ft1 * ft4;		// ft6 = (right side of screen) ? texture_fs1 : transparent
				"mul ft5, ft1, ft5 					\n" +	// ft7 = ft1 * ft4;		// ft7 = (left side of screen) ? texture_fs0 : transparent
				"add oc, ft5, ft4 					\n"; 	// outputcolor = ft7 + ft6;		// merge two images
    }
}

