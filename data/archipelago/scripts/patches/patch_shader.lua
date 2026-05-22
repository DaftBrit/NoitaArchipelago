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
	uniform vec4 AP_FRACTURE_PROGRESS;
	uniform vec4 AP_INVERT_COLOUR;
	uniform vec4 AP_PIXELATE;
	uniform vec4 AP_ZOOM_IN;
	uniform vec4 AP_ZOOM_OUT;
	uniform vec4 AP_MONOCHROME;
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
	if(AP_FLIP_HOR.x != 0.0) {
		tex_coord_.x = 1.0 - tex_coord_.x;
		tex_coord_y_inverted_.x = 1.0 - tex_coord_y_inverted_.x;
		tex_coord_glow_.x = 1.0 - tex_coord_glow_.x;
	}
	if(AP_FLIP_VER.x != 0.0) {
		tex_coord_.y = 1.0 - tex_coord_.y;
		tex_coord_y_inverted_.y = 1.0 - tex_coord_y_inverted_.y;
		tex_coord_glow_.y = 1.0 - tex_coord_glow_.y;
	}
	if(AP_ZOOM_IN.x != 0.0) {
        tex_coord_ = (tex_coord_ - 0.5) * 0.5 + 0.5;
        tex_coord_y_inverted_ = (tex_coord_y_inverted_ - 0.5) * 0.5 + 0.5;
        tex_coord_glow_ = (tex_coord_glow_ - 0.5) * 0.5 + 0.5;
	}
	if (AP_ZOOM_OUT.x != 0.0) {
        tex_coord_ = (tex_coord_ - 0.5) * 4.0 + 0.5;
        tex_coord_y_inverted_ = (tex_coord_y_inverted_ - 0.5) * 4.0 + 0.5;
        tex_coord_glow_ = (tex_coord_glow_ - 0.5) * 4.0 + 0.5;
	}
	if (AP_CAMERA_ROTATE.x != 0.0) {
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
	if(AP_144P.x != 0.0) {
		vec2 sz = vec2(192, 144);

		tex_coord.x = floor(tex_coord.x * sz.x) / sz.x;
		tex_coord_y_inverted.x = floor(tex_coord_y_inverted.x * sz.x) / sz.x;
		tex_coord_glow.x = floor(tex_coord_glow.x * sz.x) / sz.x;

		tex_coord.y = floor(tex_coord.y * sz.y) / sz.y;
		tex_coord_y_inverted.y = floor(tex_coord_y_inverted.y * sz.y) / sz.y;
		tex_coord_glow.y = floor(tex_coord_glow.y * sz.y) / sz.y;
	}
	if(AP_ZOOM_OUT.x != 0.0) {
		if(tex_coord.x < 0.0 || tex_coord.x > 1.0 || tex_coord.y < 0.0 || tex_coord.y > 1.0) {
            gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
            return;
		}
	}
	if(AP_FISH_EYE.x != 0.0) {
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
	if(AP_INVERT_COLOUR.x != 0.0) {
		color.r = 1.0 - color.r;
		color.g = 1.0 - color.g;
		color.b = 1.0 - color.b;
		gl_FragColor.rgb  = color;
	}
	if (AP_MONOCHROME.x != 0.0) {
		float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
		color = vec3(gray);
		gl_FragColor.rgb = color;
	}
	if (AP_FRACTURE.x != 0.0) {
		// clanker code
		vec2  frac_pos   = tex_coord_ * vec2(SCREEN_W, SCREEN_H) + vec2(camera_pos.x, -camera_pos.y);
		vec2  frac_base  = floor(frac_pos / 100.0);
		float frac_min1  = 9999.0;
		float frac_min2  = 9999.0;
		vec2  frac_c1    = vec2(0.0);
		vec2  frac_c2    = vec2(0.0);

		for (int dy = -1; dy <= 1; dy++) {
			for (int dx = -1; dx <= 1; dx++) {
				vec2  frac_cell   = frac_base + vec2(float(dx), float(dy));
				vec2  frac_p      = mod(frac_cell, 42.0);
				vec2  frac_jitter = fract(sin(vec2(dot(frac_p, vec2(127.1, 311.7)),
												dot(frac_p, vec2(269.5, 183.3)))) * 43758.5453);
				vec2  frac_centre = (frac_cell + frac_jitter * 0.9) * 100.0;
				float frac_d      = length(frac_pos - frac_centre);
				if      (frac_d < frac_min1) { frac_min2 = frac_min1; frac_c2 = frac_c1;
												frac_min1 = frac_d;   frac_c1 = frac_centre; }
				else if (frac_d < frac_min2) { frac_min2 = frac_d;   frac_c2 = frac_centre; }
			}
		}

		float frac_edge     = frac_min2 - frac_min1;
		float dist_from_cut = frac_edge - AP_FRACTURE_PROGRESS.x;

		// Warp
		vec2  edge_normal = normalize(frac_c2 - frac_c1);
		float warp_amount = (1.0 - smoothstep(0.0, 10.0, dist_from_cut)) * 4.0 * AP_FRACTURE_PROGRESS.x;
		vec2  warp_uv     = tex_coord_ + edge_normal * warp_amount / vec2(SCREEN_W, SCREEN_H);
		float warp_blend  = 1.0 - smoothstep(0.0, 20.0, dist_from_cut);
		gl_FragColor.rgb  = mix(gl_FragColor.rgb, texture2D(tex_fg, warp_uv).rgb, warp_blend);

		// Bevel
		vec2  light_dir   = normalize(vec2(-1.0, 1.0));
		float side_facing = dot(normalize(frac_c1 - frac_c2), light_dir);
		float edge_fade   = 1.0 - smoothstep(0.0, 12.0, dist_from_cut);
		float bevel       = 1.0 + side_facing * 0.45 * edge_fade;

		float visible     = step(AP_FRACTURE_PROGRESS.x, frac_edge);
		color = gl_FragColor.rgb * visible * bevel;
		gl_FragColor.rgb  = color;
	}
]]
)
