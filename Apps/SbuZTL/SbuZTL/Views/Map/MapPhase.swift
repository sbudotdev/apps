/// Where the user is in the one flow of the app.
enum MapPhase {
    case home
    case search
    case place(Place)
    case planning(Place)
    case preview(Place, RoutePlan)
    case guiding(Place, GuidanceModel)
}
