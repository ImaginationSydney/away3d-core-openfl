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

/** A class that provides constant values for vertical alignment of objects. */
@:enum
abstract VAlign(String)
{
	/** Top alignment. */
	public var TOP = "top";
	
	/** Centered alignment. */
	public var CENTER = "center";
	
	/** Bottom alignment. */
	public var BOTTOM = "bottom";
}