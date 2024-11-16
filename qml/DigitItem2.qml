import QtQuick 2.0

// NumberSpinner expects the rendering component to have these properties:
//
// property bool tight
// property string text
// property color color
//
// The component is supposed to adjust its implicitWidth based on its height.

Item {
    id: item

    property bool tight
    property string text
    property color color

    implicitWidth: Math.ceil(image.width * 5 / 4)

    // Strangly, HarbourHighlightIcon with exactly the same shader effect
    // doesn't quite work (produces weird rendering artifacts at certain
    // resolutions)
    ShaderEffectSource {
        id: image

        width: height * 4 / 7 // <== The aspect ratio of the svg source
        height: Math.ceil(parent.height * 7 / 8)
        anchors.centerIn: parent

        layer.enabled: true
        layer.effect: ShaderEffect {
            property variant src: image
            property color highlight: color

            vertexShader: "
                uniform highp mat4 qt_Matrix;
                attribute highp vec4 qt_Vertex;
                attribute highp vec2 qt_MultiTexCoord0;
                varying highp vec2 coord;
                void main() {
                    coord = qt_MultiTexCoord0;
                    gl_Position = qt_Matrix * qt_Vertex;
                }"
            fragmentShader: "
                varying highp vec2 coord;
                uniform sampler2D src;
                uniform lowp vec4 highlight;
                uniform lowp float qt_Opacity;
                void main() {
                    lowp vec4 tex = texture2D(src, coord);
                    gl_FragColor = vec4(vec3(dot(tex.rgb,
                                        vec3(0.344, 0.5, 0.156))),
                                             tex.a) * qt_Opacity * highlight;
                }"
        }

        sourceItem: Image {
            source: text ? ("images/digit/" + text + ".svg") : ""
            sourceSize.height: image.height
        }
    }
}
