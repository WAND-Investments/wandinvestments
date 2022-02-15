import React, { lazy } from 'react'
import { Router, Redirect, Route, Switch } from 'react-router-dom'
import PageLoader from './components/Loader/PageLoader'
import SuspenseWithChunkError from './components/SuspenseWithChunkError'
import history from './routerHistory'

// Route-based code splitting
const Home = lazy(() => import('./views/Home'))

const App: React.FC = () => {
    return (
        <Router history={history}>
        <SuspenseWithChunkError fallback={<PageLoader />}>
            <Switch>
                <Route path="/" exact>
                    <Home />
                </Route>
            </Switch>
        </SuspenseWithChunkError>
        </Router>
    )

}

export default React.memo(App)
