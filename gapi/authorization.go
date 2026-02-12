package gapi

import (
	"context"
	"fmt"
	"simplebank/token"
	"strings"

	"google.golang.org/grpc/metadata"
)

const (
	authorizationHeader = "authorization"
	authorizationBearer = "bearer"
)

func (server *Server) authorizeUser(ctx context.Context, accessibleRoles []string) (*token.Payload, error) {
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return nil, fmt.Errorf("missing metadata")
	}

	v := md.Get(authorizationHeader)
	if len(v) == 0 {
		return nil, fmt.Errorf("missing authorization header")
	}

	authHeader := v[0]
	fields := strings.Fields(authHeader)
	if len(fields) < 2 {
		return nil, fmt.Errorf("invalid authorization")
	}

	authType := fields[0]
	if authType != authorizationBearer {
		return nil, fmt.Errorf("invalid authorization type %s, support %s only", authType, authorizationBearer)
	}

	accessToken := fields[1]
	payload, err := server.tokenMaker.VerifyToken(accessToken)
	if err != nil {
		return nil, fmt.Errorf("invalid access token %w", err)
	}

	if !hasPermission(payload.Role, accessibleRoles) {
		return nil, fmt.Errorf("permission denied: role %s not allowed", payload.Role)
	}

	return payload, nil
}

func hasPermission(userRole string, accessibleRoles []string) bool {
	for _, role := range accessibleRoles {
		if userRole == role {
			return true
		}
	}
	return false
}
