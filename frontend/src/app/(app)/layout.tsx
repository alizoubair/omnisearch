import { redirect } from 'next/navigation'
import { getServerSession } from 'next-auth'
import { authOptions } from '../../lib/auth'
import { NavigationProvider } from '../../contexts/NavigationContext'
import Layout from '../../components/layout/layout'

export default async function AppLayout({
    children,
}: {
    children: React.ReactNode
}) {
    // Always check authentication
    const session = await getServerSession(authOptions)

    if (!session) {
        redirect('/auth/signin')
    }

    return (
        <NavigationProvider>
            <Layout>
                {children}
            </Layout>
        </NavigationProvider>
    )
}