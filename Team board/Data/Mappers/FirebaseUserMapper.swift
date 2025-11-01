import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct FirebaseUserMapper {
#if canImport(FirebaseAuth)
    func map(user: FirebaseAuth.User) async throws -> TeamMember {
        let role: TeamRole
        if let customClaim = try? await user.getIDTokenResult().claims["role"] as? String,
           let parsedRole = TeamRole(rawValue: customClaim) {
            role = parsedRole
        } else {
            role = .contributor
        }
        return TeamMember(
            id: Identifier(user.uid),
            displayName: user.displayName ?? "Unknown",
            email: user.email ?? "",
            avatarURL: user.photoURL,
            role: role,
            isActive: true
        )
    }
#else
    func map(user _: AnyObject) async throws -> TeamMember {
        throw RepositoryError.featureUnavailable
    }
#endif

#if canImport(FirebaseFirestore)
    func map(memberDocument: QueryDocumentSnapshot) throws -> TeamMember {
        let data = memberDocument.data()
        guard
            let displayName = data["displayName"] as? String,
            let email = data["email"] as? String,
            let roleRaw = data["role"] as? String,
            let isActive = data["isActive"] as? Bool,
            let role = TeamRole(rawValue: roleRaw)
        else {
            throw RepositoryError.decodingFailed
        }
        let avatarURL = (data["avatarURL"] as? String).flatMap { URL(string: $0) }
        return TeamMember(
            id: Identifier(memberDocument.documentID),
            displayName: displayName,
            email: email,
            avatarURL: avatarURL,
            role: role,
            isActive: isActive
        )
    }
#else
    func map(memberDocument _: AnyObject) throws -> TeamMember {
        throw RepositoryError.featureUnavailable
    }
#endif
}

