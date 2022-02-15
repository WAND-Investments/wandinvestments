import React from 'react'
import styled from 'styled-components'
import Page from '../Layout/Page'

const Wrapper = styled(Page)`
  display: flex;
  justify-content: center;
  align-items: center;
`

const PageLoader: React.FC = () => {
  return (
    <Wrapper>
      Loader...
    </Wrapper>
  )
}

export default PageLoader
