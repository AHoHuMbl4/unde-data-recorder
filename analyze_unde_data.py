import matplotlib
matplotlib.use('Agg')
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.neighbors import KNeighborsRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, r2_score
import warnings
warnings.filterwarnings('ignore')

def analyze_unde_data(csv_file_path):
    """Анализ данных UNDE"""
    print("🔬 АНАЛИЗ ДАННЫХ UNDE DATA RECORDER")
    print("=" * 50)
    
    try:
        # Пробуем разные разделители
        df = None
        for sep in [';', ',', '\t']:
            try:
                df = pd.read_csv(csv_file_path, sep=sep)
                print(f"📊 Загружено с разделителем '{sep}': {len(df)} строк, {len(df.columns)} колонок")
                if len(df.columns) > 5:  # Если много колонок, значит правильный разделитель
                    break
            except Exception as e:
                print(f"❌ Ошибка с разделителем '{sep}': {e}")
                continue
        
        if df is None:
            print("❌ Не удалось загрузить файл")
            return
            
        print(f"✅ Колонки: {list(df.columns)}")
        
        # Проверяем наличие координат
        coord_data = df[(df['x'].notna()) & (df['y'].notna())]
        unique_coords = coord_data[['x', 'y']].drop_duplicates()
        
        print(f"\n📍 СТАТИСТИКА КООРДИНАТ:")
        print(f"Всего записей: {len(df)}")
        print(f"Записей с координатами: {len(coord_data)}")
        print(f"Уникальных точек: {len(unique_coords)}")
        
        if len(unique_coords) > 0:
            print(f"Диапазон X: {coord_data['x'].min():.0f} - {coord_data['x'].max():.0f}")
            print(f"Диапазон Y: {coord_data['y'].min():.0f} - {coord_data['y'].max():.0f}")
            
            print(f"\n🧲 МАГНИТНЫЕ ДАННЫЕ:")
            mag_data = df[df['bx'].notna()]
            if len(mag_data) > 0:
                print(f"Записей с магнитными данными: {len(mag_data)}")
                print(f"Bx: {mag_data['bx'].min():.2f} - {mag_data['bx'].max():.2f} μT")
                print(f"By: {mag_data['by'].min():.2f} - {mag_data['by'].max():.2f} μT") 
                print(f"Bz: {mag_data['bz'].min():.2f} - {mag_data['bz'].max():.2f} μT")
                
                if 'magnetic_magnitude' in df.columns:
                    mag_magnitude = df[df['magnetic_magnitude'].notna()]
                    if len(mag_magnitude) > 0:
                        print(f"Магнитная интенсивность: {mag_magnitude['magnetic_magnitude'].min():.2f} - {mag_magnitude['magnetic_magnitude'].max():.2f} μT")
        
        # Анализ типов точек интереса
        if 'poi_type' in df.columns:
            poi_data = df[df['poi_type'].notna()]
            if len(poi_data) > 0:
                print(f"\n📌 ТОЧКИ ИНТЕРЕСА:")
                poi_counts = poi_data['poi_type'].value_counts()
                for poi_type, count in poi_counts.items():
                    print(f"• {poi_type}: {count} записей")
        
        # Создаем визуализацию
        if len(coord_data) > 5:
            create_visualizations(coord_data)
        
        # Тестируем ML модель
        if len(unique_coords) >= 10:
            test_ml_model(coord_data)
        else:
            print(f"\n⚠️ Для ML нужно минимум 10 уникальных точек, у вас: {len(unique_coords)}")
            
        # Оценка готовности данных
        evaluate_data_readiness(df, coord_data, unique_coords)
        
    except Exception as e:
        print(f"❌ Ошибка анализа: {e}")

def create_visualizations(data):
    """Создание графиков"""
    print(f"\n🎨 Создание визуализации...")
    
    fig, axes = plt.subplots(2, 2, figsize=(15, 12))
    fig.suptitle('UNDE - Анализ собранных данных', fontsize=16, fontweight='bold')
    
    # 1. Карта точек сбора данных
    ax1 = axes[0, 0]
    if 'magnetic_magnitude' in data.columns:
        scatter = ax1.scatter(data['x'], data['y'], 
                            c=data['magnetic_magnitude'], 
                            cmap='viridis', alpha=0.7, s=50)
        plt.colorbar(scatter, ax=ax1, label='Магнитная интенсивность (μT)')
    else:
        scatter = ax1.scatter(data['x'], data['y'], 
                            c=data['bz'], 
                            cmap='viridis', alpha=0.7, s=50)
        plt.colorbar(scatter, ax=ax1, label='Bz (μT)')
    
    ax1.set_title('Карта сбора данных')
    ax1.set_xlabel('X координата')
    ax1.set_ylabel('Y координата')
    ax1.grid(True, alpha=0.3)
    
    # 2. Распределение магнитного поля
    ax2 = axes[0, 1]
    if len(data[data['bx'].notna()]) > 0:
        ax2.hist(data['bx'].dropna(), alpha=0.7, label='Bx', bins=30, color='red')
        ax2.hist(data['by'].dropna(), alpha=0.7, label='By', bins=30, color='green')
        ax2.hist(data['bz'].dropna(), alpha=0.7, label='Bz', bins=30, color='blue')
        ax2.set_title('Распределение магнитного поля')
        ax2.set_xlabel('Значение (μT)')
        ax2.set_ylabel('Частота')
        ax2.legend()
        ax2.grid(True, alpha=0.3)
    
    # 3. Уникальные точки на карте
    ax3 = axes[1, 0]
    unique_points = data[['x', 'y']].drop_duplicates()
    ax3.scatter(unique_points['x'], unique_points['y'], 
               s=100, alpha=0.8, c='red', marker='o')
    ax3.set_title(f'Уникальные точки сбора ({len(unique_points)} шт.)')
    ax3.set_xlabel('X координата')
    ax3.set_ylabel('Y координата')
    ax3.grid(True, alpha=0.3)
    
    # 4. Количество данных по точкам
    ax4 = axes[1, 1]
    if len(data) > 0:
        point_counts = data.groupby(['x', 'y']).size().sort_values(ascending=False).head(10)
        ax4.bar(range(len(point_counts)), point_counts.values)
        ax4.set_title('ТОП-10 точек по количеству записей')
        ax4.set_xlabel('Точки')
        ax4.set_ylabel('Количество записей')
        ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('unde_data_analysis.png', dpi=300, bbox_inches='tight')
    plt.show()
    print("✅ Графики сохранены в 'unde_data_analysis.png'")

def test_ml_model(data):
    """Тестирование ML модели"""
    print(f"\n🤖 ТЕСТИРОВАНИЕ ML МОДЕЛИ")
    print("=" * 30)
    
    # Подготовка данных
    ml_data = data[(data['x'].notna()) & (data['y'].notna()) & 
                   (data['bx'].notna()) & (data['by'].notna()) & (data['bz'].notna())]
    
    if len(ml_data) < 10:
        print("❌ Недостаточно данных для ML")
        return
    
    # Признаки и целевые переменные
    features = ['bx', 'by', 'bz']
    if 'magnetic_magnitude' in ml_data.columns:
        features.append('magnetic_magnitude')
    
    X = ml_data[features]
    y = ml_data[['x', 'y']]
    
    print(f"📊 Данные для ML: {len(X)} образцов")
    print(f"🎯 Признаки: {features}")
    
    # Разделение данных
    if len(X) >= 20:
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)
    else:
        X_train, X_test, y_train, y_test = X, X, y, y
        print("⚠️ Мало данных - используем все для тестирования")
    
    # Обучение модели
    model = KNeighborsRegressor(n_neighbors=min(5, len(X_train)))
    model.fit(X_train, y_train)
    
    # Предсказания
    y_pred = model.predict(X_test)
    
    # Оценка
    mse_x = mean_squared_error(y_test['x'], y_pred[:, 0])
    mse_y = mean_squared_error(y_test['y'], y_pred[:, 1])
    rmse_overall = np.sqrt((mse_x + mse_y) / 2)
    
    print(f"📏 RMSE: {rmse_overall:.2f}")
    
    if rmse_overall < 5.0:
        print("🎉 ОТЛИЧНО! Модель показывает хорошую точность")
    elif rmse_overall < 15.0:
        print("✅ ХОРОШО! Модель работает удовлетворительно")
    else:
        print("⚠️ Нужно больше данных или лучшее покрытие")

def evaluate_data_readiness(df, coord_data, unique_coords):
    """Оценка готовности данных"""
    print(f"\n📋 ОЦЕНКА ГОТОВНОСТИ ДАННЫХ")
    print("=" * 40)
    
    score = 0
    max_score = 100
    
    # Количество уникальных точек
    if len(unique_coords) >= 30:
        points_score = 30
        print("✅ Количество точек: ОТЛИЧНО (30+ точек)")
    elif len(unique_coords) >= 20:
        points_score = 25
        print("✅ Количество точек: ХОРОШО (20+ точек)")
    elif len(unique_coords) >= 10:
        points_score = 15
        print("⚠️ Количество точек: УДОВЛЕТВОРИТЕЛЬНО (10+ точек)")
    else:
        points_score = 5
        print("❌ Количество точек: МАЛО (< 10 точек)")
    
    score += points_score
    
    # Качество магнитных данных
    mag_data = df[(df['bx'].notna()) & (df['by'].notna()) & (df['bz'].notna())]
    if len(mag_data) > len(df) * 0.8:
        mag_score = 25
        print("✅ Качество магнитных данных: ОТЛИЧНО")
    elif len(mag_data) > len(df) * 0.5:
        mag_score = 20
        print("✅ Качество магнитных данных: ХОРОШО")
    else:
        mag_score = 10
        print("⚠️ Качество магнитных данных: УДОВЛЕТВОРИТЕЛЬНО")
    
    score += mag_score
    
    # Покрытие пространства
    if len(coord_data) > 0:
        area_coverage = (coord_data['x'].max() - coord_data['x'].min()) * (coord_data['y'].max() - coord_data['y'].min())
        if area_coverage > 10000:
            coverage_score = 25
            print("✅ Покрытие пространства: ОТЛИЧНО")
        elif area_coverage > 5000:
            coverage_score = 20
            print("✅ Покрытие пространства: ХОРОШО")
        else:
            coverage_score = 15
            print("⚠️ Покрытие пространства: УДОВЛЕТВОРИТЕЛЬНО")
    else:
        coverage_score = 0
        print("❌ Покрытие пространства: НЕТ ДАННЫХ")
    
    score += coverage_score
    
    # Равномерность распределения
    if len(unique_coords) > 0:
        points_per_unit = len(coord_data) / len(unique_coords)
        if points_per_unit > 50:
            distribution_score = 20
            print("✅ Плотность данных: ОТЛИЧНО")
        elif points_per_unit > 20:
            distribution_score = 15
            print("✅ Плотность данных: ХОРОШО")
        else:
            distribution_score = 10
            print("⚠️ Плотность данных: УДОВЛЕТВОРИТЕЛЬНО")
    else:
        distribution_score = 0
    
    score += distribution_score
    
    print(f"\n🎯 ОБЩАЯ ОЦЕНКА: {score}/{max_score} ({score/max_score*100:.1f}%)")
    
    if score >= 80:
        print("🎉 ГОТОВО К СОЗДАНИЮ NAVIGATOR!")
        print("✅ Можно создавать приложение для навигации")
    elif score >= 60:
        print("✅ ХОРОШАЯ ОСНОВА")
        print("🔧 Рекомендуется добавить еще несколько точек")
    else:
        print("⚠️ НУЖНО БОЛЬШЕ ДАННЫХ")
        print("📍 Добавьте больше точек по всему помещению")

if __name__ == "__main__":
    # Анализируем больший файл
    csv_file = "/srv/flutter/projects/unde_data_recorder/1.csv"
    analyze_unde_data(csv_file)
