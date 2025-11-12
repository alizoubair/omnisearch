import { NextAuthOptions } from 'next-auth'
import CredentialsProvider from 'next-auth/providers/credentials'

export const authOptions: NextAuthOptions = {
  providers: [
    CredentialsProvider({
      name: 'credentials',
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Password', type: 'password' }
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) {
          return null
        }

        try {
          // First try to authenticate with the backend to get JWT token
          const backendUrl = process.env.BACKEND_URL || 'http://backend:8000'
          const response = await fetch(`${backendUrl}/api/v1/auth/login`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              email: credentials.email,
              password: credentials.password,
            }),
          })

          if (response.ok) {
            const tokenData = await response.json()

            // Get user info using the token
            const userResponse = await fetch(`${backendUrl}/api/v1/auth/me`, {
              headers: {
                'Authorization': `Bearer ${tokenData.access_token}`,
              },
            })

            if (userResponse.ok) {
              const userData = await userResponse.json()
              return {
                id: userData.id,
                email: userData.email,
                name: userData.name,
                image: userData.image,
                accessToken: tokenData.access_token,
              }
            }
          }

          // No fallback - authentication failed
          return null
        } catch (error) {
          console.error('Auth error:', error)
          return null
        }
      }
    })
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.id = user.id
        token.accessToken = (user as any).accessToken
      }
      return token
    },
    async session({ session, token }) {
      if (token && session.user) {
        (session.user as any).id = token.id as string
        ; (session as any).accessToken = token.accessToken
      }
      return session
    },
  },
  pages: {
    signIn: '/auth/signin',
    error: '/auth/error',
  },
  session: {
    strategy: 'jwt',
  },
  secret: process.env.NEXTAUTH_SECRET,
}