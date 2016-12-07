import Foundation

infix operator ||= : AssignmentPrecedence
func ||= (left: inout Bool, right: Bool) {
    left = left || right
}

infix operator &&= : AssignmentPrecedence
func &&= (left: inout Bool, right: Bool) {
    left = left && right
}
