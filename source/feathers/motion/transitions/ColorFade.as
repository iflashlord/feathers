/*
Feathers
Copyright 2012-2014 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.motion.transitions
{
	import starling.animation.Transitions;
	import starling.display.DisplayObject;

	public class ColorFade
	{
		protected static const SCREEN_REQUIRED_ERROR:String = "Cannot transition if both old screen and new screen are null.";

		public static function createColorFadeTransition(color:uint = 0x000000, duration:Number = 0.25, ease:Object = Transitions.EASE_OUT, tweenProperties:Object = null):Function
		{
			return function(oldScreen:DisplayObject, newScreen:DisplayObject, onComplete:Function):void
			{
				if(!oldScreen && !newScreen)
				{
					throw new ArgumentError(SCREEN_REQUIRED_ERROR);
				}

				if(oldScreen)
				{
					var activeTween:ColorFadeTween = ColorFadeTween.SCREEN_TO_TWEEN[oldScreen] as ColorFadeTween;
					if(activeTween)
					{
						//force the existing tween to finish so that the
						//properties of the old screen end up in a good state.
						activeTween.advanceTime(activeTween.totalTime);
					}
				}

				if(newScreen)
				{
					newScreen.alpha = 0;
					if(oldScreen) //oldScreen can be null, that's okay
					{
						oldScreen.alpha = 1;
					}
					new ColorFadeTween(newScreen, oldScreen, color, duration, ease, onComplete, tweenProperties);
				}
				else //we only have the old screen
				{
					oldScreen.alpha = 1;
					new ColorFadeTween(oldScreen, null, color, duration, ease, onComplete, tweenProperties);
				}
			}
		}
	}
}

import feathers.controls.IScreen;

import flash.utils.Dictionary;

import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Quad;

class ColorFadeTween extends Tween
{
	internal static const SCREEN_TO_TWEEN:Dictionary = new Dictionary(true);

	public function ColorFadeTween(target:DisplayObject, otherTarget:DisplayObject,
		color:uint, duration:Number, ease:Object, onCompleteCallback:Function,
		tweenProperties:Object)
	{
		super(target, duration, ease);
		SCREEN_TO_TWEEN[target] = this;
		if(target.alpha == 0)
		{
			this.fadeTo(1);
		}
		else
		{
			this.fadeTo(0);
		}
		if(tweenProperties)
		{
			for(var propertyName:String in tweenProperties)
			{
				this[propertyName] = tweenProperties[propertyName];
			}
		}
		if(otherTarget)
		{
			this._otherTarget = otherTarget;
			target.visible = false;
		}
		this.onUpdate = this.updateOverlay;
		this._onCompleteCallback = onCompleteCallback;
		this.onComplete = this.cleanupTween;

		var navigator:DisplayObjectContainer = target is IScreen ? IScreen(target).owner : target.parent;
		this._overlay = new Quad(navigator.width, navigator.height, color);
		this._overlay.alpha = 0;
		this._overlay.touchable = false;
		navigator.addChild(this._overlay);

		Starling.juggler.add(this);
	}

	private var _otherTarget:DisplayObject;
	private var _overlay:Quad;
	private var _onCompleteCallback:Function;

	private function updateOverlay():void
	{
		var progress:Number = this.progress;
		if(progress < 0.5)
		{
			this._overlay.alpha = progress * 2;
		}
		else
		{
			target.visible = true;
			if(this._otherTarget)
			{
				this._otherTarget.visible = false;
			}
			this._overlay.alpha = (1 - progress) * 2;
		}
	}

	private function cleanupTween():void
	{
		delete SCREEN_TO_TWEEN[this.target];
		this._overlay.removeFromParent(true);
		if(this._onCompleteCallback !== null)
		{
			this._onCompleteCallback();
		}
	}
}