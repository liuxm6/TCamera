package 
{
	import com.quasimondo.bitmapdata.CameraBitmap;
	import com.adobe.images.JPGEncoder;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.utils.*;
	import flash.external.ExternalInterface;
	import flash.media.Camera;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.events.ActivityEvent;
	import flash.events.StatusEvent;
	import flash.events.TimerEvent;
	import mx.utils.Base64Encoder;
	import flash.media.Video;

	public class TCamera extends Sprite
	{

		private var view:Sprite;
		private var w:int = 320;
		private var h:int = 240;
		private var c:int = 0;
		private var m:int = 50;

		private var notice:TextField = new TextField;
		private var sInfo:TextField = new TextField;
		private var sTime:TextField = new TextField;

		private var base64_probe:String;

		private var Cam:Camera;
		private var bmp:Bitmap;

		private var bmpObj:DisplayObject;
		private var siObj:DisplayObject;
		private var stObj:DisplayObject;
		private var video:Video;
		private var videoIsWorked:Boolean = false;
		private var timer:Timer;
		private var timerTime:Timer;

		public function TCamera()
		{
			ExternalInterface.addCallback("takePhone",takePhoneHandler);
			initUI();
		}
		/*初始化图像界面*/
		private function initUI():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			//提示文本
			notice.width = w;
			notice.height = 20;
			notice.autoSize = "center";
			notice.y = h / 2 - 20;

			//个人信息
			sInfo.width = w;
			sInfo.height = 20;
			sInfo.autoSize = "left";
			sInfo.y = h;
			sInfo.background = true;
			sInfo.backgroundColor = 0x000000;
			sInfo.textColor = 0xFFFFFF;
			
			sTime.width = w;
			sTime.height = 20;
			sTime.autoSize = "left";
			sTime.y = h+20;
			sTime.background = true;
			sTime.backgroundColor = 0x000000;
			sTime.textColor = 0xFFFFFF;

			view = new Sprite;
			addChild(view);
			view.addChild(notice);
			getCamera();
			timerTime = new Timer(1000);
			timerTime.addEventListener(TimerEvent.TIMER, displayTime);
		}
		private function getCamera():void
		{
				Cam = Camera.getCamera();
				if (Cam == null)
				{
					notice.text = "请检查摄像头是否开启!";
					return;
				}
				Cam.addEventListener(StatusEvent.STATUS, statusHandler);
				Cam.addEventListener(ActivityEvent.ACTIVITY,camActivityHandler);
				video=new Video(w,h);
				video.attachCamera(Cam);

				bmpObj = view.addChild(video);
				if (Cam.muted)
				{
					notice.text = "您不允许使用摄像头!";
					Security.showSettings(SecurityPanel.PRIVACY);
				}
				else{
					notice.text = "摄像头正常，请点击拍照";
				}
				timer = new Timer(100,m);
				camActivityHandler(null);
		}
		private function camActivityHandler(e:ActivityEvent):void {
			 if (!videoIsWorked && !Cam.muted)
			 {
						if (timer != null)
						{
								timer.addEventListener(TimerEvent.TIMER, checkCamera);
								timer.addEventListener(TimerEvent.TIMER_COMPLETE, checkCameraComplete);
								timer.start();
						}
			 }
		}
		private function checkCamera(e:TimerEvent):void {
			c=c+1;
			notice.text = "摄像头视频获取中..."+c;
			if (Cam.currentFPS > 0)
			{
					timer.stop();
					videoIsWorked = true;
					notice.text = "摄像头正常，请点击拍照";
					
					view.graphics.beginFill(0x000000);
					view.graphics.drawRect(0,h,w,40);
					view.graphics.endFill();

					var param:Object = root.loaderInfo.parameters;
					var name:String = param["name"];
					var sfz:String = param["sfz"];
					sInfo.text = "姓名:"+name+" 身份证:"+sfz;
					sTime.text = "时间:"+getDateString(new Date());

					siObj = view.addChild(sInfo);
					stObj = view.addChild(sTime);
					timerTime.start();
			}
			else{
				if(c>=m){
					checkCameraComplete();
				}
			}
		}
		private function checkCameraComplete():void {
			notice.text = "设备无法使用！(被占用)";
			timer.removeEventListener(TimerEvent.TIMER, checkCamera);
			timer.removeEventListener(TimerEvent.TIMER_COMPLETE, checkCameraComplete);
			timer = null;
			view.removeChild(bmpObj);
			view.removeChild(siObj);
			view.removeChild(stObj);
			view.graphics.clear();
			timerTime.stop();
		}
		private function statusHandler(e:StatusEvent):void {
			videoIsWorked = false;
			if (e.code=="Camera.Muted") {
					notice.text = "您不允许使用摄像头!";
					view.removeChild(bmpObj);
					view.removeChild(siObj);

					view.removeChild(stObj);
					timerTime.stop();
					view.graphics.clear();

			} else if (e.code == "Camera.Unmuted") {
					bmpObj = view.addChild(video);
			}
			c=0;
			timer = new Timer(100,m);
      camActivityHandler(null);
		}
		private function getBase64String():String {
			
			var bmd:BitmapData = new BitmapData(w,h+40);
			bmd.draw(view);
			var jpgEncoder:JPGEncoder = new JPGEncoder(85);
			var ba :ByteArray = jpgEncoder.encode(bmd);

			var base64Encoding:Base64Encoder = new Base64Encoder();
			base64Encoding.encodeBytes(ba,0,ba.length);

			base64_probe = base64Encoding.toString();
			return base64_probe;
		}
		
		private function takePhoneHandler():Array
		{
			var ret:Array = [];
			if(videoIsWorked){
				ret[0] = "True";
				var str64:String = getBase64String();
				ret[1] = str64;
				return ret;
			}
			else{
				ret[0] = "False";
				ret[1] = "摄像头不能正常工作";
			}
			return ret;
		}
		private function getDateString(date:Date):String 
		{ 
				 var days:Array = ["周日","周一","周二","周三","周四","周五","周六"];
				 var dYear:String = String(date.getFullYear()); 
				 var dMouth:String = String((date.getMonth() + 1 < 10) ? "0" : "") + (date.getMonth() + 1); 
				 var dDate:String = String((date.getDate() < 10) ? "0" : "") + date.getDate(); 
				 var ret:String = ""; 
				 ret += dYear + "年" + dMouth + "月" + dDate + "日 "; 
				 ret += days[date.getDay()] + " "; 
				 ret += ((date.getHours() < 10) ? "0" : "") + date.getHours() + ":"; 
				 ret += ((date.getMinutes() < 10) ? "0" : "") + date.getMinutes() + ":";
				 ret += ((date.getSeconds() < 10) ? "0" : "") + date.getSeconds();
				 return ret; 
		}
		private function displayTime(e:TimerEvent):void
		{
			var date:Date = new Date();
			var dateString:String = getDateString(date);
			sTime.text = "时间:"+dateString;
		}
	}
}