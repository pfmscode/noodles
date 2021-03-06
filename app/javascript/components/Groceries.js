import React from 'react'
import PropTypes from 'prop-types'

import Document from './Document'
import SuperHeading from './SuperHeading'
import Button from './Button'
import Spacer from './Spacer'
import GroceriesBlankSlate from './GroceriesBlankSlate'
import GroceriesList from './GroceriesList'
import GroceriesForm from './GroceriesForm'
import ModalLink from './ModalLink'
import Icon from './Icon'

const mailto = items =>
  `mailto:?subject=Grocery%20list&body=${encodeURIComponent(
    _.join(_.map(items, 'name'), '\n') +
      '\n\nList from Noodles: https://getnoodl.es/'
  )}`

const Groceries = ({ groceries }) => (
  <div>
    <Document mw={6} className="mbn">
      <a
        href="/groceries/new"
        className="green dn-p"
        style={{ float: 'right', marginTop: 4 }}
        aria-label="Add item"
      >
        <Icon glyph="plus" />
      </a>
      <SuperHeading className="f1-ns mvn-ns">Grocery List</SuperHeading>
      {_.isEmpty(groceries) ? (
        <GroceriesBlankSlate />
      ) : (
        [
          <GroceriesList items={groceries} key="list" />,
          <GroceriesForm key="add" />
        ]
      )}
    </Document>
    <footer className="flex flex-cols flex-rows-ns fac-ns fjc-ns fjc phm mtm mbxl dn-p">
      <div className="flex-i fac">
        <Icon glyph="share" size={28} className="grey-3 mrs" />
        <Button color="grey-3" sm href={mailto(groceries)}>
          Email
        </Button>
        <Spacer x={16} />
        <Button color="grey-3" sm data-behavior="print">
          Print
        </Button>
      </div>
      <Spacer x={16} y={8} />
      <div
        className="dn dib-ns grey-4"
        style={{ width: 0, height: 32, borderLeft: '1px solid currentColor' }}
      />
      <Spacer x={16} y={8} />
      <Button color="grey-3" sm href="/groceries/past">
        View past items
      </Button>
    </footer>
  </div>
)

Groceries.propTypes = {
  groceries: PropTypes.array.isRequired
}

export default Groceries
