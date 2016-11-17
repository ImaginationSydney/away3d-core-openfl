// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2014 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package away3d.textfield;

import openfl.errors.Error;

/** A class that provides constant values for horizontal alignment of objects. */
@:enum
abstract HAlign(String) from String
{
	/** Left alignment. */
	var LEFT   = "left";
	
	/** Centered alignement. */
	var CENTER = "center";
	
	/** Right alignment. */
	var RIGHT  = "right";
}