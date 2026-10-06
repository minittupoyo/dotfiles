import QtQuick
import QtTest
import ".."

Item {
    width: 560
    height: 100
    SearchField { id: field; width: 500 }
    SignalSpy { id: navigation; target: field; signalName: "navigate" }
    SignalSpy { id: submission; target: field; signalName: "submit" }
    TestCase {
        name: "SearchInteraction"
        when: windowShown
        function init() {
            field.text = "";
            field.focusInput();
            navigation.clear(); submission.clear();
        }
        function test_keyboard_navigation_keeps_input_focus() {
            const input = findChild(field, "searchInput");
            verify(input.activeFocus);
            keyClick(Qt.Key_Down);
            compare(navigation.count, 1);
            compare(navigation.signalArguments[0][0], 1);
            keyClick(Qt.Key_Up);
            compare(navigation.signalArguments[1][0], -1);
            verify(input.activeFocus);
            keyClick(Qt.Key_Return);
            compare(submission.count, 1);
        }
        function test_typing_does_not_submit() {
            keyClick(Qt.Key_K);
            keyClick(Qt.Key_I);
            keyClick(Qt.Key_T);
            compare(field.text, "kit");
            compare(submission.count, 0);
            compare(navigation.count, 0);
        }
        function test_japanese_text_and_clear() {
            field.text = "日本語";
            wait(10);
            compare(field.text, "日本語");
            const button = findChild(field, "clearButton");
            verify(button.visible);
            mouseClick(button, button.width / 2, button.height / 2);
            compare(field.text, "");
            verify(findChild(field, "searchInput").activeFocus);
        }
    }
}
