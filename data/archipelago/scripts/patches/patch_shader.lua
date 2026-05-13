-- Mostly stolen from Fair Mod

local function escape(str)
	return str:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")
end

local shader_append = function(path, find, append)
	-- add to next line
	local file = ModTextFileGetContent(path)
	local pos = string.find(file, escape(find))
	if pos then
		local pos2 = string.find(file, "\n", pos)
		if pos2 then
			local before = string.sub(file, 1, pos2)
			local after = string.sub(file, pos2 + 1)
			ModTextFileSetContent(path, before .. append .. after)
		end
	end
end

local shader_vars = [[
	uniform vec4 AP_144P;
	uniform vec4 AP_CAMERA_ROTATE;
	uniform vec4 AP_CRYSTAL;
	uniform vec4 AP_FISH_EYE;
	uniform vec4 AP_FLIP_HOR;
	uniform vec4 AP_FLIP_VER;
	uniform vec4 AP_FRACTURE;
	uniform vec4 AP_INVERT_COLOUR;
	uniform vec4 AP_PIXELATE;
	uniform vec4 AP_ZOOM_IN;
	uniform vec4 AP_ZOOM_OUT;
]]

shader_append("data/shaders/post_final.frag",
	"varying vec2 tex_coord_fogofwar;",
	shader_vars
)

shader_append("data/shaders/post_final.vert",
	"varying vec2 tex_coord_fogofwar;",
	shader_vars
)

shader_append("data/shaders/post_final.vert",
	"tex_coord_glow_ = gl_TexCoord[1].xy;",
	[[
	if(AP_FLIP_HOR.x == 1.0) {
		tex_coord_.x = 1.0 - tex_coord_.x;
		tex_coord_y_inverted_.x = 1.0 - tex_coord_y_inverted_.x;
		tex_coord_glow_.x = 1.0 - tex_coord_glow_.x;
	}
	if(AP_FLIP_VER.x == 1.0) {
		tex_coord_.y = 1.0 - tex_coord_.y;
		tex_coord_y_inverted_.y = 1.0 - tex_coord_y_inverted_.y;
		tex_coord_glow_.y = 1.0 - tex_coord_glow_.y;
	}
	if(AP_ZOOM_IN.x == 1.0) {
        tex_coord_ = (tex_coord_ - 0.5) * 0.5 + 0.5;
        tex_coord_y_inverted_ = (tex_coord_y_inverted_ - 0.5) * 0.5 + 0.5;
        tex_coord_glow_ = (tex_coord_glow_ - 0.5) * 0.5 + 0.5;
	}
	if (AP_ZOOM_OUT.x == 1.0) {
        tex_coord_ = (tex_coord_ - 0.5) * 4.0 + 0.5;
        tex_coord_y_inverted_ = (tex_coord_y_inverted_ - 0.5) * 4.0 + 0.5;
        tex_coord_glow_ = (tex_coord_glow_ - 0.5) * 4.0 + 0.5;
	}
	if (AP_CAMERA_ROTATE.x == 1.0) {
		float angle = radians(45.0);

		mat2 rot = mat2(
			cos(angle), -sin(angle),
			sin(angle),  cos(angle)
		);

		gl_Position.xy = rot * gl_Position.xy;
	}
]]
)

shader_append("data/shaders/post_final.frag",
	"vec2 tex_coord_glow = tex_coord_glow_;",
	[[
	if(AP_144P.x == 1.0) {
		vec2 sz = vec2(192, 144);

		tex_coord.x = floor(tex_coord.x * sz.x) / sz.x;
		tex_coord_y_inverted.x = floor(tex_coord_y_inverted.x * sz.x) / sz.x;
		tex_coord_glow.x = floor(tex_coord_glow.x * sz.x) / sz.x;

		tex_coord.y = floor(tex_coord.y * sz.y) / sz.y;
		tex_coord_y_inverted.y = floor(tex_coord_y_inverted.y * sz.y) / sz.y;
		tex_coord_glow.y = floor(tex_coord_glow.y * sz.y) / sz.y;
	}
	if(AP_ZOOM_OUT.x == 1.0) {
		if(tex_coord.x < 0.0 || tex_coord.x > 1.0 || tex_coord.y < 0.0 || tex_coord.y > 1.0) {
            gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
            return;
		}
	}
	if(AP_FISH_EYE.x == 1.0) {
		// clanker code
        vec2 uv = tex_coord * 1.5 - 1.5 / 2;
        float r = length(uv);
        float strength = 0.5;
        vec2 warped = uv * (1.0 + strength * pow(r + 0.3, 3.0));
        warped = warped * 0.5 + 0.5;

        if(warped.x < 0.0 || warped.x > 1.0 || warped.y < 0.0 || warped.y > 1.0) {
            gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
            return;
        }

        vec2 delta = warped - tex_coord_;
        tex_coord = warped;
        tex_coord_y_inverted = tex_coord_y_inverted_ + delta;
        tex_coord_glow = tex_coord_glow_ + delta;
	}
]]
)

shader_append("data/shaders/post_final.frag",
	"gl_FragColor.rgb  = color;",
	[[
	if(AP_INVERT_COLOUR.x == 1.0) {
		color.r = 1.0 - color.r;
		color.g = 1.0 - color.g;
		color.b = 1.0 - color.b;
		gl_FragColor.rgb  = color;
	}
]]
)
