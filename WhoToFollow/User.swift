import Mapper

struct User: Mappable {
    let id: Int
    let name: String
    let avatarUrl: String
    
    init(map: Mapper) throws {
        try id = map.from("id")
        try name = map.from("login")
        try avatarUrl = map.from("avatar_url")
    }
}
