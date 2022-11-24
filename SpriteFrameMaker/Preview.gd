extends ViewportContainer


onready var previewSprite = $Viewport/PreviewSprite
onready var viewport = $Viewport

func _ready() :
	center_sprite()

func update_sprite(spriteFrame : SpriteFrames) :
	previewSprite.frames = spriteFrame
	update_sprite_position()

func update_sprite_position() :
	previewSprite.position = $Viewport.size/2

func _on_Viewport_size_changed():
	update_sprite_position()

func change_animation(animationName : String) :
	previewSprite.animation = animationName
	previewSprite.playing = true

func center_sprite() -> void :
	previewSprite.position = viewport.size/2
