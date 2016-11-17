package away3d.stereo;

import away3d.debug.Debug;
#if (openfl >= "4.0.0")
	import openfl.utils.AGALMiniAssembler;
#else
	import openfl.display3D._shaders.AGLSLShaderUtils;
#end
import away3d.core.managers.RTTBufferManager;
import away3d.core.managers.Stage3DProxy;
import away3d.stereo.methods.InterleavedStereoRenderMethod;
import away3d.stereo.methods.StereoRenderMethodBase;
import openfl.Vector;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.Context3DTriangleFace;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.Texture;
import openfl.events.Event;

#if html5
import starling.openfl.AGLSLParser;
#end

class StereoRenderer {
    public var renderMethod(get, set):StereoRenderMethodBase;

    private var _leftTexture:Texture;
    private var _rightTexture:Texture;
    private var _rttManager:RTTBufferManager;
    private var _program3D:Program3D;
    private var _method:StereoRenderMethodBase;
    private var _program3DInvalid:Bool;
    private var _leftTextureInvalid:Bool;
    private var _rightTextureInvalid:Bool;
	
	#if (openfl >= "4.0.0")
	private static var assembler = new AGALMiniAssembler();
	#end
	
    public function new(renderMethod:StereoRenderMethodBase = null) {
        _program3DInvalid = true;
        _leftTextureInvalid = true;
        _rightTextureInvalid = true;
        _method = renderMethod;
        
        if (_method == null)
            _method = new InterleavedStereoRenderMethod();
    }

    private function get_renderMethod():StereoRenderMethodBase {
        return _method;
    }

    private function set_renderMethod(value:StereoRenderMethodBase):StereoRenderMethodBase {
        _method = value;
        _program3DInvalid = true;
        
        return value;
    }

    public function getLeftInputTexture(stage3DProxy:Stage3DProxy):Texture {
        if (_leftTextureInvalid) {
            if (_rttManager == null) 
                setupRTTManager(stage3DProxy);
			
			_leftTexture = stage3DProxy.context3D.createTexture(_rttManager.textureWidth, _rttManager.textureHeight, Context3DTextureFormat.BGRA, true);
            _leftTextureInvalid = false;
        }
        
        return _leftTexture;
    }

    public function getRightInputTexture(stage3DProxy:Stage3DProxy):Texture {
        if (_rightTextureInvalid) {
            if (_rttManager == null) 
                setupRTTManager(stage3DProxy);
            
            _rightTexture = stage3DProxy.context3D.createTexture(_rttManager.textureWidth, _rttManager.textureHeight, Context3DTextureFormat.BGRA, true);
            _rightTextureInvalid = false;
        }
        
        return _rightTexture;
    }

    public function render(stage3DProxy:Stage3DProxy):Void {
        var vertexBuffer:VertexBuffer3D;
        var indexBuffer:IndexBuffer3D;
        var context:Context3D;
        if (_rttManager == null)
            setupRTTManager(stage3DProxy);
        
        stage3DProxy.scissorRect = null;
        stage3DProxy.setRenderTarget(null, true);
        context = stage3DProxy.context3D;
        vertexBuffer = _rttManager.renderToScreenVertexBuffer;
        indexBuffer = _rttManager.indexBuffer;
        
        context.setProgram(getProgram3D(stage3DProxy));

        _method.activate(stage3DProxy);

        context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
        context.setVertexBufferAt(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
        context.setTextureAt(0, _leftTexture);
        context.setTextureAt(1, _rightTexture);
		        
        context.clear(0.0, 0.0, 0.0, 1.0);
        stage3DProxy.drawTriangles(indexBuffer, 0, 2);
        
        // Clean up
        _method.deactivate(stage3DProxy);
        
        context.setTextureAt(0, null);
        context.setTextureAt(1, null);
        context.setVertexBufferAt(0, null, 0, null);
        context.setVertexBufferAt(1, null, 2, null);
		
		var data:Vector<Float> = Vector.ofArray([-1,-1/stage3DProxy.height,0.5,0]);
		stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 15, data, 1);
		//_program3DInvalid = true;
    }

    private function setupRTTManager(stage3DProxy:Stage3DProxy):Void {
        _rttManager = RTTBufferManager.getInstance(stage3DProxy);
        _rttManager.addEventListener(Event.RESIZE, onRttBufferManagerResize);
    }

    private function getProgram3D(stage3DProxy:Stage3DProxy):Program3D {
        if (_program3DInvalid) {
			
			#if html5
			AGLSLParser.FLIP_TEXTURE = false;
			#end
            var vertexCode:String;
            var fragmentCode:String;
            vertexCode = "";
			
			vertexCode += "mov op, va0				\n";
			
			vertexCode += "mov vt0, va1				\n";
			//vertexCode += "mul vt0.y, va0.y, vc5.z	\n";
			//vertexCode += "add vt0.y, vt0.y, vc15.z	\n";
			
			vertexCode += "mov v0, va0				\n";
			vertexCode += "mov v1, vt0				\n";
			
            fragmentCode = _method.getFragmentCode();
			
            if (_program3D != null) 
                _program3D.dispose();

            _program3D = stage3DProxy.context3D.createProgram();
            
			#if (openfl >= "4.0.0")
				_program3D.upload(
					assembler.assemble(Context3DProgramType.VERTEX, vertexCode),
					assembler.assemble(Context3DProgramType.FRAGMENT, fragmentCode)
				);
			#else
				var vertexByteCode = AGLSLShaderUtils.createShader(Context3DProgramType.VERTEX, vertexCode);
				var fragmentByteCode = AGLSLShaderUtils.createShader(Context3DProgramType.FRAGMENT, fragmentCode);
				_program3D.upload(vertexByteCode, fragmentByteCode);
			#end
			
            _program3DInvalid = false;
        }
		#if html5
		AGLSLParser.FLIP_TEXTURE = true;
		#end
		return _program3D;
    }

    private function onRttBufferManagerResize(ev:Event):Void {
        _leftTextureInvalid = true;
        _rightTextureInvalid = true;
        _method.invalidateTextureSize();
    }
}

