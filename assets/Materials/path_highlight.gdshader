shader_type canvas_item;

uniform vec4 color : source_color;
uniform vec4 invalid_color : source_color;
uniform float pulse_speed = 3.0;
uniform bool is_pulsing = false;
uniform float opacity = 0.8;

instance uniform bool is_valid;

/**
* 0 = east, 1 = west, 2 = south, 3 = north 
*/
instance uniform int direction = 0;

varying vec2 vertex_position;

void vertex() {
	vertex_position.xy = VERTEX;
	
}

void fragment() {
	float pulse_factor = 1.0;
	
	if(is_pulsing){
	 	pulse_factor = pow(sin(TIME * pulse_speed), 2);	
	}
	vec4 tex_color = texture(TEXTURE, UV);
	vec4 shifted_color;
	
	if(direction == 0){
		tex_color = texture(TEXTURE, UV);
	}else if(direction == 1){
		tex_color = texture(TEXTURE, vec2(1.0 - UV.x, UV.y)) ;
	}
	else if(direction == 2){
		tex_color = texture(TEXTURE, vec2(UV.y, UV.x)) ;
	}
	else if(direction == 3){
		tex_color = texture(TEXTURE,vec2(1.0 - UV.y, 1.0 - UV.x)) ;
	}
	
	if(is_valid) {
		shifted_color = tex_color * color * opacity;	
	}else {
		shifted_color = tex_color * invalid_color * opacity;
	}
	
	
	COLOR = vec4(
		shifted_color.xyz, 
		shifted_color.a * pulse_factor);
}
