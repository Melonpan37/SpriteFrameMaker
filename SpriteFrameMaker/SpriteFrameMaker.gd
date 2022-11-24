extends Control

const SELF_NAME = "SpriteFrameMaker"
const LOG_PREFIX = "D : " + SELF_NAME + " -> "
const LOG_ERROR_PREFIX = "E : " + SELF_NAME + " -> "


onready var preview = $VBoxContainer/Preview
onready var previewSprite = $VBoxContainer/Preview/Viewport/PreviewSprite
onready var loadButton = $VBoxContainer/LoadButton
onready var saveButton = $VBoxContainer/SaveButton
onready var upButton = $VBoxContainer/PreviewButtons/UpButton
onready var rightButton = $VBoxContainer/PreviewButtons/RightButton
onready var downButton = $VBoxContainer/PreviewButtons/DownButton
onready var leftButton = $VBoxContainer/PreviewButtons/LeftButton
onready var walkButton = $VBoxContainer/PreviewButtons/MovementButton
onready var fileDialog = $FileDialog
onready var disabledButtons = [
	upButton,
	rightButton,
	downButton,
	leftButton,
	walkButton,
	saveButton
]


export var SPRITE_SIZE_X : int = 16
export var SPRITE_SIZE_Y : int = 16

export var default_load_sprite_path : String = "res://assets/sprites/"
export var default_save_sprite_frames_path : String = "res://actors/"

export var default_walking_state_prefix = "walk_"
export var default_idle_state_prefix = "idle_"

enum {DETECT, GBST, HORIZONTAL, HORIZONTAL_MIRROR, RPGM, UNDETECTED}
const DEFAULT_IMAGE_TYPES : PoolStringArray = PoolStringArray([
	"detect",
	"gbst",
	"horizontal",
	"horizontal_mirror",
	"rpgm"
])
export var default_image_type : int  = DETECT

var DEFAULT_ANIMATION_LOCATIONS = {
	default_idle_state_prefix + "up"		:	[9],
	default_idle_state_prefix + "right"		:	[3],
	default_idle_state_prefix + "down"		:	[0],
	default_idle_state_prefix + "left"		:	[6],
	default_walking_state_prefix + "up"	 	:	[10, 9, 11, 9],
	default_walking_state_prefix + "right"	:	[4, 3, 5, 3],
	default_walking_state_prefix + "down"	:	[1, 0, 2, 0],
	default_walking_state_prefix + "left"	:	[7, 6, 8, 6],
}

#preview vars
var spriteFrame : SpriteFrames = null

var spriteName : String = ""

func setup_file_dialog() :
	fileDialog.mode = 0
	fileDialog.access = 0
	fileDialog.window_title = "Select Sprite"
	fileDialog.add_filter("*.png")
	fileDialog.current_dir = default_load_sprite_path

func disable_buttons() :
	for button in disabledButtons :
		button.disabled = true

func enable_buttons() :
	for button in disabledButtons :
		button.disabled = false

func _ready():
	disable_buttons()
	setup_file_dialog()

func build_spriteframe(spritePath) -> SpriteFrames :
	var sourceImage = Image.new()
	sourceImage.load(spritePath)
	var frames : Array = []
	var opt = default_image_type
	if opt == DETECT :
		opt = detect_sprite_type(sourceImage)
	match opt :
		GBST :
			for i in range(9) :
				var frame = Image.new()
				frame.create(SPRITE_SIZE_X, SPRITE_SIZE_Y, false, Image.FORMAT_RGBA8)
				frame.blit_rect(sourceImage, Rect2(SPRITE_SIZE_X*i, 0, SPRITE_SIZE_X, SPRITE_SIZE_Y), Vector2.ZERO)
				for x in frame.get_width() :
					for y in frame.get_height() :
						if frame.get_pixel(x, y) == Color("65ff00") :
							frame.set_pixel(x, y, Color(0, 0, 0, 0))
				var frameTexture = ImageTexture.new()
				frameTexture.create_from_image(frame, 0)
				frames.append(frameTexture)
			for i in range(3) :
				var flippedFrame = Image.new()
				flippedFrame.create(SPRITE_SIZE_X, SPRITE_SIZE_Y, false, Image.FORMAT_RGBA8)
				flippedFrame.blit_rect(sourceImage,  Rect2(SPRITE_SIZE_X*(3+i), 0, SPRITE_SIZE_X, SPRITE_SIZE_Y), Vector2.ZERO)
				flippedFrame.flip_x()
				for x in flippedFrame.get_width() :
					for y in flippedFrame.get_height() :
						if flippedFrame.get_pixel(x, y) == Color("65ff00") :
							flippedFrame.set_pixel(x, y, Color(0, 0, 0, 0))
				var frameTexture = ImageTexture.new()
				frameTexture.create_from_image(flippedFrame, 0)
				frames.insert(3+i, frameTexture)
		HORIZONTAL :
			for i in range(12) :
				var frame = Image.new()
				frame.create(SPRITE_SIZE_X, SPRITE_SIZE_Y, false, Image.FORMAT_RGBA8)
				frame.blit_rect(sourceImage, Rect2(SPRITE_SIZE_X*i, 0, SPRITE_SIZE_X, SPRITE_SIZE_Y), Vector2.ZERO)
				var frameTexture = ImageTexture.new()
				frameTexture.create_from_image(frame, 0)
				frames.append(frameTexture)
		HORIZONTAL_MIRROR :
			for i in range(9) :
				var frame = Image.new()
				frame.create(SPRITE_SIZE_X, SPRITE_SIZE_Y, false, Image.FORMAT_RGBA8)
				frame.blit_rect(sourceImage, Rect2(SPRITE_SIZE_X*i, 0, SPRITE_SIZE_X, SPRITE_SIZE_Y), Vector2.ZERO)
				var frameTexture = ImageTexture.new()
				frameTexture.create_from_image(frame, 0)
				frames.append(frameTexture)
			for i in range(3) :
				var flippedFrame = Image.new()
				flippedFrame.create(SPRITE_SIZE_X, SPRITE_SIZE_Y, false, Image.FORMAT_RGBA8)
				flippedFrame.blit_rect(sourceImage,  Rect2(SPRITE_SIZE_X*(3+i), 0, SPRITE_SIZE_X, SPRITE_SIZE_Y), Vector2.ZERO)
				flippedFrame.flip_x()
				var frameTexture = ImageTexture.new()
				frameTexture.create_from_image(flippedFrame, 0)
				frames.insert(3+i, frameTexture)
		RPGM :
			for i in range(12) :
				var frame = Image.new()
				frame.create(SPRITE_SIZE_X, SPRITE_SIZE_Y, false, Image.FORMAT_RGBA8)
				frame.blit_rect(sourceImage, Rect2(SPRITE_SIZE_X*(i%3), SPRITE_SIZE_Y*(i%4), SPRITE_SIZE_X, SPRITE_SIZE_Y), Vector2.ZERO)
				var frameTexture = ImageTexture.new()
				frameTexture.create_from_image(frame, 0)
				frames.append(frameTexture)
		UNDETECTED : 
			return null
		_ :
			print("Not yet implemented")
			return null
	
	var spriteFrame = SpriteFrames.new()
	spriteFrame.add_frame("default", frames[0])
	for animationName in DEFAULT_ANIMATION_LOCATIONS.keys() :
		spriteFrame.add_animation(animationName)
		var framePosition : int = 0
		for frameIndex in DEFAULT_ANIMATION_LOCATIONS[animationName] : 
			spriteFrame.add_frame(animationName, frames[frameIndex], framePosition)
			framePosition += 1
	
	return spriteFrame

func detect_sprite_type(sprite : Image) -> int :
	print(LOG_PREFIX + "tryng to detect image type")
	var imgSize = sprite.get_size()
	if imgSize.x == 9*SPRITE_SIZE_X && imgSize.y == SPRITE_SIZE_Y :
		if sprite.get_pixel(1, 1) == Color("65ff00") : #not very accurate
			print(LOG_PREFIX + "detected GBST image type")
			return GBST
		else : 
			print(LOG_PREFIX + "detected HORIZONTAL_MIRRORED image type")
			return HORIZONTAL_MIRROR
	if imgSize.x == 12*SPRITE_SIZE_X && imgSize.y == SPRITE_SIZE_Y :
		print(LOG_PREFIX + "detected HORIZONTAL image type")
		return HORIZONTAL
	if imgSize.x == 3*SPRITE_SIZE_X && imgSize.y == 4*SPRITE_SIZE_Y :
		print(LOG_PREFIX + "detected RPGM image type")
		return RPGM
	
	printerr(LOG_ERROR_PREFIX + "cannot detect image size : try setting it manually or change SPRITE_SIZE_X/Y")
	return UNDETECTED

func load_sprite() -> void :
	fileDialog.popup_centered(get_viewport_rect().size*0.7)
	var imagePath : String = yield(fileDialog, "file_selected")
	spriteFrame = build_spriteframe(imagePath)
	if spriteFrame == null : return
	previewSprite.frames = spriteFrame
	previewSprite.animation = default_idle_state_prefix + "down"
	previewSprite.playing = true
	
	var splitPath : PoolStringArray = imagePath.split("/")
	spriteName = splitPath[splitPath.size()-1]
	spriteName = spriteName.left(spriteName.find("."))
	spriteName = spriteName.capitalize()
	
	enable_buttons()
	
	print(LOG_PREFIX + "successfully builded SpriteFrames for " + spriteName)

func save_sprite_frame() -> void :
	var err = ResourceSaver.save(default_save_sprite_frames_path + spriteName + ".tres", spriteFrame, 0)
	if err != OK : printerr(LOG_ERROR_PREFIX + "Error saving SpriteFrame, errno : " + String(err))
	else : print(LOG_PREFIX + "Resource saved with success in path : " + default_save_sprite_frames_path + spriteName + ".tres")

#------------------------BUTTONS CALLBACKS------------------------------

func _on_LoadButton_button_down():
	load_sprite()

func _on_SaveButton_button_down():
	save_sprite_frame()

func _on_MovementButton_toggled(button_pressed):
	var currentAnimation : String = previewSprite.animation
	if button_pressed == true : 
		currentAnimation = currentAnimation.substr(default_idle_state_prefix.length())
		print(currentAnimation)
		currentAnimation = default_walking_state_prefix + currentAnimation
	else :
		currentAnimation = currentAnimation.substr(default_walking_state_prefix.length())
		currentAnimation = default_idle_state_prefix + currentAnimation
	previewSprite.animation = currentAnimation

func _on_UpButton_button_down():
	var currentAnimation : String = previewSprite.animation
	if currentAnimation.begins_with(default_idle_state_prefix) :
		currentAnimation = currentAnimation.substr(0, default_idle_state_prefix.length())
	else :
		currentAnimation = currentAnimation.substr(0, default_walking_state_prefix.length())
	currentAnimation += "up"
	previewSprite.animation = currentAnimation

func _on_RightButton_button_down():
	var currentAnimation : String = previewSprite.animation
	if currentAnimation.begins_with(default_idle_state_prefix) :
		currentAnimation = currentAnimation.substr(0, default_idle_state_prefix.length())
	else :
		currentAnimation = currentAnimation.substr(0, default_walking_state_prefix.length())
	currentAnimation += "right"
	previewSprite.animation = currentAnimation

func _on_DownButton_button_down():
	var currentAnimation : String = previewSprite.animation
	if currentAnimation.begins_with(default_idle_state_prefix) :
		currentAnimation = currentAnimation.substr(0, default_idle_state_prefix.length())
	else :
		currentAnimation = currentAnimation.substr(0, default_walking_state_prefix.length())
	currentAnimation += "down"
	previewSprite.animation = currentAnimation

func _on_LeftButton_button_down():
	var currentAnimation : String = previewSprite.animation
	if currentAnimation.begins_with(default_idle_state_prefix) :
		currentAnimation = currentAnimation.substr(0, default_idle_state_prefix.length())
	else :
		currentAnimation = currentAnimation.substr(0, default_walking_state_prefix.length())
	currentAnimation += "left"
	previewSprite.animation = currentAnimation


