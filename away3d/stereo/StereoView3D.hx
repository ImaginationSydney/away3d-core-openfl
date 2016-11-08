package away3d.stereo;

import away3d.cameras.lenses.PerspectiveLens;
import openfl.errors.Error;
import away3d.cameras.Camera3D;
import away3d.containers.Scene3D;
import away3d.containers.View3D;
import away3d.core.render.RendererBase;
import away3d.stereo.methods.StereoRenderMethodBase;
import openfl.display3D.textures.Texture;
import openfl.geom.Vector3D;

class StereoView3D extends View3D {
    public var stereoRenderMethod(get, set):StereoRenderMethodBase;
    public var stereoEnabled(get, set):Bool;

    private var _stereoCam:StereoCamera3D;
    private var _stereoRenderer:StereoRenderer;
    private var _stereoEnabled:Bool;
	var lens:PerspectiveLens;
	var standardFieldOfView:Float;
	
    public function new(scene:Scene3D = null, camera:Camera3D = null, renderer:RendererBase = null, stereoRenderMethod:StereoRenderMethodBase = null, forceSoftware:Bool = false, profile:String = "baseline", _contextIndex:Int=-1) {
        
		if (camera == null){
			_stereoCam = new StereoCamera3D();
			_stereoCam.stereoOffset = 10;
			_stereoCam.position = new Vector3D();
			
			//standardFieldOfView = 10;
			//lens = new PerspectiveLens(standardFieldOfView);
			//_stereoCam.lens = lens;
			cast (_stereoCam.lens, PerspectiveLens).fieldOfView /= 2;
			this.camera = _stereoCam;
		}
		else {
			this.camera = camera;
		}
		
		super(scene, camera, renderer, forceSoftware, profile, _contextIndex);
        
        _stereoRenderer = new StereoRenderer(stereoRenderMethod);
    }

    private function get_stereoRenderMethod():StereoRenderMethodBase {
        return _stereoRenderer.renderMethod;
    }

    private function set_stereoRenderMethod(value:StereoRenderMethodBase):StereoRenderMethodBase {
        _stereoRenderer.renderMethod = value;
        return value;
    }

    override private function get_camera():Camera3D {
        return _stereoCam;
    }

    override private function set_camera(value:Camera3D):Camera3D {
        if (value == _stereoCam) return value;
        if (Std.is(value, StereoCamera3D)) _stereoCam = cast((value), StereoCamera3D)
        else throw new Error("StereoView3D must be used with StereoCamera3D");
        return value;
    }

    private function get_stereoEnabled():Bool {
        return _stereoEnabled;
    }

    private function set_stereoEnabled(val:Bool):Bool {
        _stereoEnabled = val;
		return val;
    }

    override public function render():Void {
        if (_stereoEnabled) {
            // reset or update render settings
            if (_backBufferInvalid) updateBackBuffer();
            if (!_parentIsStage) updateGlobalPos();
            
            updateTime();
            
			//lens.fieldOfView = 60;
			stage.dispatchEvent(new StereoEvent(StereoEvent.LEFT));
            renderWithCamera(_stereoCam.leftCamera, _stereoRenderer.getLeftInputTexture(_stage3DProxy), true);
			stage.dispatchEvent(new StereoEvent(StereoEvent.RIGHT));
            renderWithCamera(_stereoCam.rightCamera, _stereoRenderer.getRightInputTexture(_stage3DProxy), false);  
            _stereoRenderer.render(_stage3DProxy);
            
            if (!_shareContext) _stage3DProxy.context3D.present();
            
            _mouse3DManager.fireMouseEvents();
        } else {
            //_camera = _stereoCam.leftCamera;
			//stage.dispatchEvent(new StereoEvent(StereoEvent.LEFT));
			
			//lens.fieldOfView = 80;
			_aspectRatio = _width / _height * 2;
			
			//cast(_stereoCam.leftCamera.lens, PerspectiveLens)
			stage.dispatchEvent(new StereoEvent(StereoEvent.LEFT));
            renderWithCamera(_stereoCam, _stereoRenderer.getLeftInputTexture(_stage3DProxy), true);
			
            //super.render();
        }

    }

    private function renderWithCamera(cam:Camera3D, texture:Texture, doMouse:Bool):Void {
        _entityCollector.clear();
        _camera = cam;
        //_camera.lens.aspectRatio = _aspectRatio;
        _entityCollector.camera = _camera;
        updateViewSizeData();

        // Always use RTT for stereo rendering
        _renderer.textureRatioX = _rttBufferManager.textureRatioX;
        _renderer.textureRatioY = _rttBufferManager.textureRatioY;

        // collect stuff to render
        _scene.traversePartitions(_entityCollector);

        // update picking
        if (doMouse) _mouse3DManager.updateCollider(this);
        if (_requireDepthRender) renderDepthPrepass(_entityCollector);
        if (_filter3DRenderer != null && _stage3DProxy.context3D != null) {
            _renderer.render(_entityCollector, _filter3DRenderer.getMainInputTexture(_stage3DProxy), _rttBufferManager.renderToTextureRect);
            _filter3DRenderer.render(_stage3DProxy, camera, _depthRender);
            if (!_shareContext) _stage3DProxy.context3D.present();
        }

        else {
            _renderer.shareContext = _shareContext;
            if (_shareContext) _renderer.render(_entityCollector, texture, _scissorRect)
            else _renderer.render(_entityCollector, texture, _rttBufferManager.renderToTextureRect);
        }

        // clean up data for this render
        _entityCollector.cleanUp();
    }
}

