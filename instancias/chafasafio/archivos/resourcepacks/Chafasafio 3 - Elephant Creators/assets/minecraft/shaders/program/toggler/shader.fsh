#version 130

uniform sampler2D DiffuseSampler;
uniform sampler2D ControlSampler;

uniform float Time; // Variable para animar el efecto
uniform vec2 Frequency; // Frecuencia del desplazamiento
uniform vec2 WobbleAmount; // Cantidad de desplazamiento

in vec2 texCoord;
in vec2 oneTexel;

out vec4 fragColor;

vec3 hue(float h) {
    float r = abs(h * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(h * 6.0 - 2.0);
    float b = 2.0 - abs(h * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

vec3 HSVtoRGB(vec3 hsv) {
    return ((hue(hsv.x) - 1.0) * hsv.y + 1.0) * hsv.z;
}

vec3 RGBtoHSV(vec3 rgb) {
    vec3 hsv = vec3(0.0);
    hsv.z = max(rgb.r, max(rgb.g, rgb.b));
    float minVal = min(rgb.r, min(rgb.g, rgb.b));
    float c = hsv.z - minVal;

    if (c != 0.0) {
        hsv.y = c / hsv.z;
        vec3 delta = (hsv.z - rgb) / c;
        delta.rgb -= delta.brg;
        delta.rg += vec2(2.0, 4.0);
        if (rgb.r >= hsv.z) {
            hsv.x = delta.b;
        } else if (rgb.g >= hsv.z) {
            hsv.x = delta.r;
        } else {
            hsv.x = delta.g;
        }
        hsv.x = fract(hsv.x / 6.0);
    }
    return hsv;
}

void main() {
    vec4 prev_color = texture(DiffuseSampler, texCoord);
    fragColor = prev_color; // Inicializa fragColor con el color previo

    // Channel #1
    vec4 control_color = texelFetch(ControlSampler, ivec2(0, 1), 0);
    switch(int(control_color.b * 255.)) {
        case 1:
            // Efecto de desplazamiento basado en el tiempo
            float xOffset = sin(texCoord.y * Frequency.x + Time * 3.1415926535 * 2.0) * WobbleAmount.x;
            float yOffset = cos(texCoord.x * Frequency.y + Time * 3.1415926535 * 2.0) * WobbleAmount.y;
            vec2 offset = vec2(xOffset, yOffset);
            vec4 rgb = texture(DiffuseSampler, texCoord + offset);
            vec3 hsv = RGBtoHSV(rgb.rgb);
            hsv.x = fract(hsv.x + Time); // Cambia el tono con el tiempo
            fragColor = vec4(HSVtoRGB(hsv), 1.0); // Asigna el nuevo color
            break;
        case 2:
            fragColor.r += 0.07; // Aumenta el rojo para que se vea más cálido
            fragColor.g += 0.04; // Aumenta ligeramente el verde para un tono más marrón
            fragColor.b += -0.05; // Disminuye el azul para que el color sea más terroso
            break;

    }

    // Channel #2 (opcional)
    control_color = texelFetch(ControlSampler, ivec2(0, 2), 0);
    switch(int(control_color.b * 255.)) {
        case 1:
            fragColor.rgb = prev_color.rgb;  // Restaurar el color original si se activa el canal 2
            break;
    }

    // Aquí puedes agregar más lógica si es necesario

    // Aplicar un overlay si está presente
    vec4 overlay = vec4(0.0); // Asumiendo que no hay overlay por defecto
    if (overlay.a > 0.0) {
        fragColor.rgb = mix(fragColor.rgb, overlay.rgb, overlay.a).rgb;
    }
}
