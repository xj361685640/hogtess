#line 2

uniform mat4 MVP;

#if _VERTEX_

out int vElementID;

void main()
{
    vElementID = gl_VertexID >> 2;
}


#elif _TESS_CONTROL_

layout(vertices = 4) out;

in int vElementID[];
out int tcElementID[];

uniform vec2 screenSize;

float subdiv(float pixels)
{
    return max(pixels / 10, 1);
}

void main()
{
    if (gl_InvocationID == 0)
    {
        int elemID = vElementID[gl_InvocationID];

        vec4 vert[4];
        vert[0] = lagrangeQuadSolution(0, 0); // TODO: use nodal value directly
        vert[1] = lagrangeQuadSolution(1, 0);
        vert[2] = lagrangeQuadSolution(0, 1);
        vert[3] = lagrangeQuadSolution(1, 1);

        vec2 screen[4];
        for (int i = 0; i < 4; i++) {
            vec4 t = MVP * vert[i];
            vec2 ndc = t.xy / t.w;
            screen[i] = ndc * screenSize * 0.5;
        }

        vec4 len = vec4(distance(screen[1], screen[0]),
                        distance(screen[2], screen[1]),
                        distance(screen[3], screen[2]),
                        distance(screen[0], screen[3]));

        gl_TessLevelOuter[1] = subdiv(len.x);
        gl_TessLevelOuter[2] = subdiv(len.y);
        gl_TessLevelOuter[3] = subdiv(len.z);
        gl_TessLevelOuter[0] = subdiv(len.w);

        gl_TessLevelInner[1] = (gl_TessLevelOuter[0] + gl_TessLevelOuter[2])*0.5;
        gl_TessLevelInner[0] = (gl_TessLevelOuter[1] + gl_TessLevelOuter[3])*0.5;

        tcElementID[gl_InvocationID] = elemID;
    }
}


#elif _TESS_EVAL_

layout(quads) in;

in int tcElementID[];

void main()
{
    int elemID = tcElementID[0];

    vec4 position = lagrangeQuadSolution(gl_TessCoord.x, gl_TessCoord.y);

    position.x += float(elemID) * 0.01;

    gl_Position = MVP * position;
}


#elif _FRAGMENT_

out vec4 fragColor;

void main()
{
    fragColor = vec4(0.0, 0.0, 0.0, 1.0);
}

#endif
