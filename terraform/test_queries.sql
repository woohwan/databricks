-- 적재 검증용 sanity check 쿼리

SELECT 'customers' AS table_name, count(*) AS row_count FROM customers
UNION ALL
SELECT 'products', count(*) FROM products
UNION ALL
SELECT 'orders', count(*) FROM orders
UNION ALL
SELECT 'order_items', count(*) FROM order_items
UNION ALL
SELECT 'returns', count(*) FROM returns;

-- 등급별 고객 분포
SELECT grade, count(*) AS customers, sum(total_spent) AS total_spent
FROM customers
GROUP BY grade
ORDER BY total_spent DESC;

-- 주문 상태 분포
SELECT status, count(*) AS orders
FROM orders
GROUP BY status
ORDER BY orders DESC;

-- 참조 무결성 확인: order_items가 가리키는 order_id/product_id가 실제 존재하는지
SELECT count(*) AS orphan_order_items
FROM order_items oi
LEFT JOIN orders o ON o.id = oi.order_id
LEFT JOIN products p ON p.id = oi.product_id
WHERE o.id IS NULL OR p.id IS NULL;

-- 매출 상위 5개 상품
SELECT p.name, sum(oi.subtotal) AS revenue
FROM order_items oi
JOIN products p ON p.id = oi.product_id
GROUP BY p.name
ORDER BY revenue DESC
LIMIT 5;
