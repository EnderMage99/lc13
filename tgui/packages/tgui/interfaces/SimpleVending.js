import { classes } from 'common/react';
import { useBackend, useLocalState } from '../backend';
import { Box, Button, Input, Section, Table } from '../components';
import { Window } from '../layouts';

const SimpleVendingRow = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    product,
    productStock,
    expanded,
    onToggle,
  } = props;
  const {
    onstation,
    user,
  } = data;

  const free = !onstation || product.price === 0;
  const stock = productStock;
  const unlimited = stock === -1;
  const outOfStock = !unlimited && stock <= 0;

  // Stock color
  let stockColor = 'good';
  if (outOfStock) {
    stockColor = 'bad';
  } else if (!unlimited && stock <= (product.max_amount / 2)) {
    stockColor = 'average';
  }

  // Stock display text
  let stockText = 'unlimited';
  if (!unlimited) {
    stockText = outOfStock ? 'sold out' : `${stock} in stock`;
  }

  // Check if user can afford
  const canAfford = free || (user && user.cash >= product.price);
  const canPurchase = !outOfStock && canAfford;

  return (
    <>
      <Table.Row className="candystripe">
        <Table.Cell collapsing>
          <span
            className={classes([
              'vending32x32',
              product.icon_path,
            ])}
            style={{
              'vertical-align': 'middle',
              'horizontal-align': 'middle',
            }} />
        </Table.Cell>
        <Table.Cell>
          <Button
            fluid
            color="transparent"
            content={product.name}
            onClick={() => onToggle()}
            style={{
              'text-align': 'left',
              'font-weight': 'bold',
            }} />
        </Table.Cell>
        <Table.Cell collapsing textAlign="center">
          <Box color={stockColor}>
            {stockText}
          </Box>
        </Table.Cell>
        <Table.Cell collapsing textAlign="center">
          <Button
            fluid
            disabled={!canPurchase}
            content={free ? 'FREE' : `${product.price} ahn`}
            onClick={() => act('vend', {
              'path': product.path,
            })} />
        </Table.Cell>
      </Table.Row>
      {expanded && (
        <Table.Row>
          <Table.Cell colSpan="4">
            <Box
              italic
              color="label"
              style={{
                'padding-left': '2em',
                'padding-top': '0.5em',
                'padding-bottom': '0.5em',
              }}>
              {product.desc}
            </Box>
          </Table.Cell>
        </Table.Row>
      )}
    </>
  );
};

export const SimpleVending = (props, context) => {
  const { act, data } = useBackend(context);

  // Extract data from backend
  const {
    onstation,
    products = [],
    enable_search,
    vendor_name,
    user,
    stock = {},
    stored_ahn = 0,
  } = data;

  const [searchQuery, setSearchQuery] = useLocalState(context, 'searchQuery', '');
  const [expandedItems, setExpandedItems] = useLocalState(context, 'expandedItems', {});

  // Filter products based on search query
  let filteredProducts = products;
  if (enable_search && searchQuery) {
    const query = searchQuery.toLowerCase();
    filteredProducts = products.filter(product =>
      product.name.toLowerCase().includes(query)
      || product.desc.toLowerCase().includes(query)
    );
  }

  // Toggle item expansion
  const toggleItem = (itemName) => {
    setExpandedItems({
      ...expandedItems,
      [itemName]: !expandedItems[itemName],
    });
  };

  return (
    <Window
      title={vendor_name || "Simple Vending Machine"}
      width={500}
      height={650}>
      <Window.Content scrollable>
        {!!onstation && (
          <Section title="User">
            {data.user && (
              <Box>
                Welcome, <b>{data.user.name}</b>,
                {' '}
                <b>{data.user.job || 'Unemployed'}</b>!
                <br />
                Your balance is <b>{data.user.cash} ahn</b>.
                <br />
                Machine balance: <b>{stored_ahn} ahn</b>
              </Box>
            ) || (
              <Box color="light-grey">
                No registered ID card!<br />
                Please contact your local HoP!
                <br />
                <br />
                Machine balance: <b>{stored_ahn} ahn</b>
              </Box>
            )}
          </Section>
        )}
        <Section title="Products">
          {enable_search && (
            <Box mb={1}>
              <Input
                fluid
                placeholder="Search products..."
                value={searchQuery}
                onInput={(e, value) => setSearchQuery(value)} />
            </Box>
          )}
          {filteredProducts.length === 0 && (
            <Box color="label" textAlign="center" italic>
              No products found.
            </Box>
          )}
          {filteredProducts.length > 0 && (
            <Table>
              {filteredProducts.map(product => (
                <SimpleVendingRow
                  key={product.name}
                  product={product}
                  productStock={stock[product.name]}
                  expanded={expandedItems[product.name]}
                  onToggle={() => toggleItem(product.name)} />
              ))}
            </Table>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
